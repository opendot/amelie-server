require 'rails_helper'
require 'shared/signin.rb'

describe Overrides::RegistrationsController, :type => :request do
  include_context "signin"

  before(:all) do
    @password = "t3stp4ssw0rd"
    @headers = auth_params = {
      'Content-Type' => 'application/json',
      'accept' => 'application/airett.v1',
    }
  end

  before(:each) do
    @id = SecureRandom.uuid()
  end

  def signup_request(id, email, type, name, surname)
    user = {
      id: id,
      email: email,
      password: @password,
      confirm_password: @password,
      type: type,
      name: name,
      surname: surname,
    }

    post "/auth", params: user.to_json, headers: @headers
  end

  context "correct signup" do
    before(:each) do
      @email = "test@mail.it"
      @type = "GuestUser"
      @name = "Test"
      @surname = "User"

      signup_request(@id, @email, @type, @name, @surname)
    end

    it "return 401 UNAUTHORIZED" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "return an error message" do
      body = JSON.parse(response.body)
      expect(body["errors"][0]).to eq(I18n.t("errors.users.signup_local"))
    end

    it "didn't create a User" do
      expect(User.exists?(@id)).to be false
    end

  end

  context "researcher signup" do
    before(:each) do
      @email = "researcher.test@mail.it"
      @type = "Researcher"
      @name = "Test"
      @surname = "Researcher"

      signup_request(@id, @email, @type, @name, @surname)
    end

    it "return 401 UNAUTHORIZED" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "didn't create a Researcher" do
      expect(Researcher.exists?(@id)).to be false
    end
  end

  context "parent signup" do
    before(:each) do
      @email = "parent.test@mail.it"
      @type = "Parent"
      @name = "Test"
      @surname = "Parent"

      signup_request(@id, @email, @type, @name, @surname)
    end

    it "return 401 UNAUTHORIZED" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "didn't create a Parent" do
      expect(Parent.exists?(@id)).to be false
    end
  end

  context "guest signup" do
    before(:each) do
      @email = "guest.test@mail.it"
      @type = "GuestUser"
      @name = "Test"
      @surname = "Guest"

      signup_request(@id, @email, @type, @name, @surname)
    end

    it "return 401 UNAUTHORIZED" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "didn't create a GuestUser" do
      expect(GuestUser.exists?(@id)).to be false
    end
  end

end