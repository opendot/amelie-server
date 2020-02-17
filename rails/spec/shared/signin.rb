RSpec.configure do |rspec|
  # This config option will be enabled by default on RSpec 4,
  # but for reasons of backwards compatibility, you have to
  # set it on RSpec 3.
  #
  # It causes the host group and examples to inherit metadata
  # from the shared context.
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context "signin", :shared_context => :metadata do

  def signin_researcher( to_online_server = false)
    signin_user( Researcher.first, "password", to_online_server)
  end

  def signin_parent( to_online_server = false)
    signin_user( Parent.first, "password", to_online_server)
  end

  def signin_superadmin( to_online_server = false)
    signin_user( Superadmin.first, "password", to_online_server)
  end

  def signin_guest
    signin_user( GuestUser.first, ENV["GUEST_USER_PASSWORD"], false)
  end

  def signin_user( user, password, to_online_server = false)
    @current_user = user
    post to_online_server ? "/sign_in" : "/auth/sign_in",
      :params => {:email => @current_user.email, :password => password}
    @headers = get_auth_params_from_login_response_headers(response)
  end

  def get_auth_params_from_login_response_headers(response)
    client = response.headers['client']
      token = response.headers['access-token']
      expiry = response.headers['expiry']
      token_type = response.headers['token-type']  
      uid =   response.headers['uid']  

      auth_params = {
                      'Content-Type' => 'application/json',
                      'access-token' => token,
                      'client' => client,
                      'uid' => uid,
                      'expiry' => expiry,
                      'token_type' => token_type
                    }
      auth_params
  end

end

RSpec.configure do |rspec|
  rspec.include_context "signin", :include_shared => true
end