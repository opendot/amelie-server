require 'rails_helper'
require 'shared/signin.rb'

RSpec.describe Api::V1::UsersController, type: :request do
  include_context "signin"

  context "show" do

    before(:each) do
      @another_user = Researcher.first
    end

    context "with authentication" do
      before(:each) do
        signin_superadmin

        get "/users/#{@another_user.id}", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

    end
    
    context "without authentication" do
      before(:each) do
        get "/users/#{@another_user.id}", headers: @headers
      end

      it "return 401 UNAUTHORIZED" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

  end

  context "show" do

    before(:each) do
      signin_researcher

      @user= User.first
      get "/users/#{@user.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

  end

  context "update" do

    before(:each) do
      signin_researcher
    end

    context "self" do
      before(:each) do
        # This route is available only in _remote environment
        @new_name = "Tester"
        @original_surname = @current_user.surname
        user = {
          name: @new_name,
        }
        put "/users/#{@current_user.id}", params: user.to_json, headers: @headers
      end

      it "return 202 ACCEPTED" do
        expect(response).to have_http_status(:accepted)
      end

      it "updated the user name" do
        expect(User.find(@current_user.id).name).to eq(@new_name)
      end

    end

    context "another user" do
      before(:each) do
        # This route is available only in _remote environment
        @another = User.where.not(id: @current_user.id).first
        @new_name = "Tester"
        @original_surname = @current_user.surname
        user = {
          name: @new_name,
        }
        put "/users/#{@another.id}", params: user.to_json, headers: @headers
      end

      it "return 401 UNAUTHORIZED" do
        expect(response).to have_http_status(:unauthorized)
      end

    end

  end

  context "on_network" do

    it "doesn't require authentication" do
      headers = {}
      expect {
        post "/users/on_network", headers: headers
      }.to_not raise_error
    end

    it "return 200 OK" do
      post "/users/on_network"
      expect(response).to have_http_status(:ok)
    end

    it "send a socket message to desktop" do
      expect {
        post "/users/on_network"
      }.to have_broadcasted_to("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}").with("{\"type\":\"USER_ON_NETWORK\"}")
    end

  end

  context "disable users" do

    before(:each) do
      signin_superadmin
      puts @current_user.inspect
      puts @headers.inspect
      @users_disabled = Parent.where.not(id: @current_user.id).limit(1)

      users = {users: []}
      puts "users"
      @users_disabled.each { |u| users[:users] << {id: u.id, disabled: true}}
      put "/users/disable", params: users.to_json, headers: @headers
    end

    it "return 403 FORBIDDEN" do
      expect(response).to have_http_status(:forbidden)
    end

  end

end
