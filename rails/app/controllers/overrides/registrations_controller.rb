class Overrides::RegistrationsController < DeviseTokenAuth::RegistrationsController
  before_action :allow_signup_on_environment


  def create
    if !params.has_key?(:id)
      params[:id] = SecureRandom.uuid()
    end
    super do |resource| # continue the dflt creation process
      if resource.persisted?
        UserMailer.with(
            current_user: resource,
            ).created_user.deliver_now
      end
    end
  end



  private

  def sign_up_params
    params.permit(:name, :surname, :email, :password, :password_confirmation, :birthdate, :id, :type, :organization, :role, :description)
  end

  def render_create_success
    render json: @resource, serializer: Api::V1::UserSerializer
  end

  # Prevent user creation and edit in the wrong environments
  def allow_signup_on_environment
    # Guests must be created in *_local environment, others must be created in *_remote
    local_user_types = %w(GuestUser)

    if Rails.env.ends_with?("remote") || (Rails.env.test? && ENV["TEST_ROUTES"] == "remote")
      if params.has_key?(:type) && local_user_types.include?(params[:type])
        return render json: {errors: [ I18n.t(:error) ] }, status: :unauthorized
      end
    else
      # Prevent user creation in *_local environment
      return render json: {errors: [ I18n.t("errors.users.signup_local") ] }, status: :unauthorized
    end
  end
  
end
