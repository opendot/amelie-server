class Api::V1::SignInController < DeviseTokenAuth::ApplicationController
  skip_before_action :authenticate_user!

  def create
    # Verify if it's a check for saved creadentials
    return if check_valid_credentials

    unless sign_in_params[:email] || sign_in_params[:password]
      render json: {errors: ["#{I18n.t :error_user_login_params}"]}, status: :bad_request
      return
    end

    create_response = {}
    begin
      RestClient::Request.execute(method: :post, url: "#{ENV['ONLINE_SERVER_ADDRESS']}/auth/sign_in", payload: {email: sign_in_params[:email], password: sign_in_params[:password], server_ip: sign_in_params[:server_ip]}, headers: {params:{"Content-Type": "json", "Accept":"application/airett.v1"}}, timeout: 3){ |response, request, result|
        create_response[:headers] = response.headers
        create_response[:body] = response.body
        body = JSON.parse(response.body, :symbolize_names => true)
        if response.code < 300
          unless User.exists?(body[:id])
            User.create(id: body[:id], email: params[:email], password: params[:password], password_confirmation: params[:password], name: body[:name], surname: body[:surname], type: body[:type], birthdate: body[:birthdate])
          end
        else
          render json: create_response[:body], status: response.code
          return
        end
        @resource = find_resource("email", create_response[:headers][:uid])
      }
    rescue
      logger.error "Can't sign in to online server. Try to login locally."
      render json: {}, status: 	:see_other
      return
    end

    unless params[:server_ip].blank?
      $SERVER_IP = params[:server_ip]
    end

    if @resource.nil?
      render json: {errors: ["#{I18n.t :error_user_login}"]}, status: :not_found
      return
    end

    @tokens = {}
    create_token(create_response[:headers][:client], create_response[:headers][:access_token], create_response[:headers][:expiry].to_i)

    @resource.tokens["#{create_response[:headers][:client]}"] = @tokens["#{create_response[:headers][:client]}"]

    @resource.save!

    response.headers['access-token'] = create_response[:headers][:access_token]
    response.headers['client'] = create_response[:headers][:client]
    response.headers['expiry'] = create_response[:headers][:expiry]
    response.headers['uid'] = create_response[:headers][:uid]
    response.headers['token-type'] = create_response[:headers][:token_type]
    
    render json: create_response[:body], status: :created
  end

  private

  def sign_in_params
    params.permit(:email, :password, :server_ip)
  end

  def find_resource(field, value)
    # fix for mysql default case insensitivity
    q = "#{field.to_s} = ? AND provider='email'"
    if ActiveRecord::Base.connection.adapter_name.downcase.starts_with? 'mysql'
      q = "BINARY " + q
    end

    @resource = User.where(q, value).first
  end

  def create_token(client_id, token, expiry)
    @tokens["#{client_id}"] = {
      token: BCrypt::Password.create(token),
      expiry: expiry
    }
    [client_id, token, expiry]
  end

  def check_valid_credentials
    token = request.headers['access-token']
    client = request.headers['client']
    uid = request.headers['uid']
    expiry = request.headers['expiry']
    type = request.headers['token-type']

    return false if token.nil? || client.nil? || uid.nil?

    user = User.find_by(uid: uid)
    return false if user.nil?
    success = user.valid_token?(token, client)

    if success
      response.headers['access-token'] = token
      response.headers['client'] = client
      response.headers['expiry'] = expiry
      response.headers['uid'] = uid
      response.headers['token-type'] = type
      unless params[:server_ip].blank?
        $SERVER_IP = params[:server_ip]
      end
      render json: user, serializer: Api::V1::UserSerializer, status: :ok
    end
    return success
  end
end
