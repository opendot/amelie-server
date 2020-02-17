class PackageMailer < ApplicationMailer

  def created_package
    @current_user = params[:current_user]
    @temporary_url  = params[:temporary_url]
    @expiration_days  = params[:expiration_days]
    mail(to: @current_user.email, subject: I18n.t("mailers.package.created_package.subject"))
  end

  def generic_error
    @current_user = params[:current_user]
    @error_message  = params[:error_message]
    @error_full_message  = params[:error_full_message]
    mail(to: @current_user.email, subject: I18n.t("mailers.package.generic_error.subject"))
  end

  def carrierwave_upload_error
    @current_user = params[:current_user]
    @error_message  = params[:error_message]
    @error_full_message  = params[:error_full_message]
    mail(to: @current_user.email, subject: I18n.t("mailers.package.carrierwave_upload_error.subject"))
  end

end
