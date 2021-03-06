class FormTemplatesController < ApplicationController
  # Load
  load_resource only: [:preview, :use, :destroy, :edit, :update]
  before_filter :response_fieldable_exists?, except: [:preview, :index, :destroy, :edit, :update, :create] # also authorizes

  # admin
  def index
    respond_to do |format|
      format.html {}

      format.json do
        search_results = FormTemplate.searcher(params)
        render_serialized search_results[:results], meta: search_results[:meta]
      end
    end
  end

  def edit
  end

  def update
    @form_template.update_attributes(form_template_params)
    render json: { status: "success" }
  end

  def pick_template
    @form_templates = FormTemplate.paginate(page: params[:page])
  end

  def create
    @form_template = FormTemplate.create(name: "")
    redirect_to edit_form_template_path(@form_template)
  end

  def create_from_existing
    @form_template = FormTemplate.create(name: form_template_params[:name],
                                         form_options: @response_fieldable.form_options)

    @response_fieldable.response_fields.each do |response_field|
      ResponseField.create pick(response_field, *ResponseField::ALLOWED_PARAMS)
                           .merge(response_fieldable: @form_template)
    end

    render json: @form_template
  end

  def preview
  end

  def use
    @response_fieldable.use_form_template!(@form_template)
    flash[:success] = t('flashes.copied_form_template')
    redirect_to redirect_path_for(@response_fieldable)
  end

  def destroy
    @form_template.destroy
    redirect_to form_templates_path
  end

  private
  def response_fieldable_exists?
    @response_fieldable = find_polymorphic(:response_fieldable)
    authorize! :manage_response_fields, @response_fieldable
  end

  def form_template_params
    params.require(:form_template).permit(:name)
  end

  def redirect_path_for(response_fieldable)
    case response_fieldable.class.name
    when "Project"
      response_fields_project_path(response_fieldable.id)
    else
      :back
    end
  end
end
