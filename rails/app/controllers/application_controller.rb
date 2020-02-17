class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  serialization_scope :view_context

  before_action :authenticate_user!, unless: :devise_controller? || :passwords_controller?, except: [:not_found, :root, :login]
  authorize_resource unless: :devise_controller? || :passwords_controller?, except: [:not_found, :root, :login]

  def not_found
    render json: { errors: ['Endpoint non trovato.'] }, status: :not_found
  end

  def root
    render json: {}, status: :ok
  end

  # This is to capture every RecordNotFound error and display them like every other error
  rescue_from ActiveRecord::RecordNotFound  do |e|
    render json:{ errors: [e.message] }, status: :bad_request
  end

  rescue_from CanCan::AccessDenied do |e|
    render json:{ errors: [ I18n.t(:error_user_unauthorized, user_type: current_user.type), e.message] }, status: :forbidden
  end

  rescue_from ActionController::ParameterMissing do |parameter_missing_exception|
    error = {}
    error[parameter_missing_exception.param] = ['parameter is required']
    response = { errors: [error] }
    respond_to do |format|
      format.json { render json: response, status: :unprocessable_entity }
    end
  end
end
