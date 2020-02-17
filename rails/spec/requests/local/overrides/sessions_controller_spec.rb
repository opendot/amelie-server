require 'rails_helper'
require 'shared/signin.rb'

describe Overrides::SessionsController, :type => :request do
  include_context "signin"

  context "guest signin" do
    before(:each) do
      signin_guest
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

  end

end