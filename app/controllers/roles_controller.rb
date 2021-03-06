class RolesController < ApplicationController
  # Load
  load_resource :role, except: [:create]

  # Authorize
  before_filter :ensure_is_admin_or_god

  def index
    @roles = Role.not_god.order("name").paginate(page: params[:page])
  end

  def new
  end

  def create
    Role.create(role_params)
    redirect_to roles_path
  end

  def edit
  end

  def update
    @role.update_attributes(role_params)
    redirect_to roles_path
  end

  def destroy
    if @role.default
      flash[:error] = I18n.t('flashes.cant_delete_default_role')
    elsif @role.undeletable?
      flash[:error] = I18n.t('flashes.role_undeletable')
    else
      flash[:error] = I18n.t('flashes.users_role_deleted', count: @role.officers.count) if @role.officers.count > 0
      @role.destroy
    end

    redirect_to roles_path
  end

  def set_as_default
    Role.where(default: true).update_all(default: false)
    @role.update_attributes(default: true)
    redirect_to :back
  end

  def duplicate
    new_role = Role.create(
      name: @role.name + " copy",
      role_type: @role.role_type,
      permissions: @role.permissions
    )

    redirect_to edit_role_path(new_role)
  end

  private
  def role_params
    filtered_params = { name: params[:role][:name] }

    filtered_params[:permissions] = case params[:quick_permissions]
    when "user"
      Role.low_permissions
    when "supervisor"
      Role.high_permissions
    else
      params[:role][:permissions]
    end

    filtered_params
  end
end
