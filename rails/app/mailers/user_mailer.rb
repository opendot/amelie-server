class UserMailer < ApplicationMailer

  def created_user
    @current_user = params[:current_user]
    puts @current_user
    mail(to: @current_user.email, subject: I18n.t("mailers.users.created_user.subject"))
  end

end
