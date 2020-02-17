require 'rails/application_controller'

class UtilityPagesController < Rails::ApplicationController
  def reset_password
    @uid = params[:uid]
    @client_id = params[:client_id]
    @token = params[:token]
    @expiry = params[:expiry]
    render file: Rails.root.join('app/views/pages', 'reset_password_form.html.erb')
  end
end
