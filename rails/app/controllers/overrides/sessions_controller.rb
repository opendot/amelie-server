require 'rest-client'
class Overrides::SessionsController < DeviseTokenAuth::SessionsController
  # This is called after a successful login.
  def render_create_success
    unless params[:server_ip].blank?
      $SERVER_IP = params[:server_ip]
    end
    render json: @resource, serializer: Api::V1::UserSerializer
  end
end