require 'rails_helper'
require 'shared/signin.rb'

describe Api::V1::PackagesController, :type => :request do
  include_context "signin"

  before(:all) do
    signin_researcher
  end

  context "ability" do

    # context "researcher" do
    #   before(:each) do
    #     @type = "Researcher"
    #     @current_user.update!(type: @type)

    #     get "/packages", headers: @headers
    #   end

    #   it "return 200 OK" do
    #     expect(response).to have_http_status(:ok)
    #   end
    # end

    # context "superadmin" do
    #   before(:each) do
    #     @type = "Superadmin"
    #     @current_user.update!(type: @type)

    #     get "/packages", headers: @headers
    #   end

    #   it "return 200 OK" do
    #     expect(response).to have_http_status(:ok)
    #   end
    # end

    # context "parent" do
    #   before(:each) do
    #     @type = "Parent"
    #     @current_user.update!(type: @type)

    #     get "/packages", headers: @headers
    #   end

    #   it "return 403 FORBIDDEN" do
    #     expect(response).to have_http_status(:forbidden)
    #   end
    # end

    # context "guest" do
    #   before(:each) do
    #     @type = "GuestUser"
    #     @current_user.update!(type: @type)

    #     get "/packages", headers: @headers
    #   end

    #   it "return 403 FORBIDDEN" do
    #     expect(response).to have_http_status(:forbidden)
    #   end
    # end

  end

end