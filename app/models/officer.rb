# == Schema Information
#
# Table name: officers
#
#  id         :integer          not null, primary key
#  role_id    :integer
#  title      :string(255)
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class Officer < ActiveRecord::Base
  include SharedUserMethods

  has_many :collaborators
  has_many :projects, -> { uniq(true) }, through: :collaborators
  has_many :questions
  has_many :bid_reviews, dependent: :destroy

  has_searcher starting_query: Officer.joins("INNER JOIN users ON users.owner_id = officers.id AND users.owner_type = 'Officer'")

  pg_search_scope :full_search, against: [:name, :title],
                                associated_against: { user: [:email], role: [:name] },
                                using: { tsearch: { prefix: true } }

  belongs_to :role

  def self.add_params_to_query(query, params, args)
    if params[:q] && !params[:q].blank?
      query = query.full_search(params[:q])
    end

    # @todo sort role
    if params[:sort] == "email"
      query = query.order("lower(users.email) #{params[:direction] == 'asc' ? 'asc' : 'desc' }")
    elsif params[:sort] == "name" || params[:sort].blank?
      query = query.order("NULLIF(lower(name), '') #{params[:direction] == 'asc' ? 'asc NULLS LAST' : 'desc' }")
    end

    query
  end

  def self.event_types
    types = [:collaborator_added, :you_were_added, :bulk_collaborators_added]
    types.push(:question_asked) if GlobalConfig.instance[:questions_enabled]
    types.push(:project_comment) if GlobalConfig.instance[:comments_enabled]
    types.push(:bid_comment) if GlobalConfig.instance[:bid_review_enabled] && GlobalConfig.instance[:comments_enabled]
    types.push(:bid_awarded, :bid_unawarded) if GlobalConfig.instance[:bid_review_enabled]
    types.push(:bid_submitted) if GlobalConfig.instance[:bid_submission_enabled]
    Event.event_types.only(*types)
  end

  def self.invite!(email, project, role_id = nil)
    role_id ||= Role.where(default: true).first.id
    officer = Officer.create(role_id: role_id)
    user = User.create(email: email, owner: officer).reset_perishable_token!
    officer.send_invitation_email!(project)
    return officer
  end

  def send_invitation_email!(project)
    Mailer.invite_email(self, project).deliver
  end

  handle_asynchronously :send_invitation_email!

  def role_type
    role ? Role.role_types[role.role_type] : :user
  end

  def is_admin_or_god
    role_type.in? [:admin, :god]
  end

  question_alias :is_admin_or_god

  def never_allowed_to(permission)
    !is_admin_or_god? && role.permissions[permission] == "never"
  end

  def default_notification_preferences
    Officer.event_types.except(:collaborator_added, :bid_submitted, :bulk_collaborators_added).values
  end
end
