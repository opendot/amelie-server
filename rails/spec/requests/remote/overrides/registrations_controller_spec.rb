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

  def signup_request(id, email, type, name, surname, organization = nil, role = nil, description = nil)
    user = {
      id: id,
      email: email,
      password: @password,
      confirm_password: @password,
      type: type,
      name: name,
      surname: surname,
      organization: organization,
      role: role,
      description: description,
    }

    post "/auth", params: user.to_json, headers: @headers
  end

  context "correct signup" do
    before(:each) do
      @email = "test@mail.it"
      @type = "Researcher"
      @name = "Test"
      @surname = "User"

      signup_request(@id, @email, @type, @name, @surname)
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

  end

  context "wrong signup" do
    before(:each) do
      @email = "test@mail.it"
      @type = "Researcher"
      @name = "Test"
      @surname = "User"

    end

    it "require mail" do
      signup_request(@id, nil, @type, @name, @surname)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "check mail format" do
      signup_request(@id, "testmail.it", @type, @name, @surname)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "require type" do
      signup_request(@id, @email, nil, @name, @surname)
      expect(response).to have_http_status(:unprocessable_entity)
    end

  end

  context "researcher signup" do
    before(:each) do
      @email = "researcher.test@mail.it"
      @type = "Researcher"
      @name = "Test"
      @surname = "Researcher"
      @organization = "University"
      @role = "Professor"
      @description = "Lorem ipsum"

      signup_request(@id, @email, @type, @name, @surname, @organization, @role, @description)
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "created a Researcher" do
      expect(Researcher.exists?(@id)).to be true
    end

    it "returned organization" do
      researcher = JSON.parse(response.body)
      expect(researcher["organization"]).to eq(@organization)
    end

    it "returned description" do
      researcher = JSON.parse(response.body)
      expect(researcher["description"]).to eq(@description)
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

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "created a Parent" do
      expect(Parent.exists?(@id)).to be true
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