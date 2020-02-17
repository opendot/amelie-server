require 'rails_helper'
require 'shared/signin.rb'

RSpec.describe Api::V1::Patients::LevelsController, type: :request do
  include_context "signin"
  before(:all) do
    signin_researcher
  end

  before(:each) do
    @patient = Patient.find("patient0")
    @current_user.add_patient(@patient)
  end

  context "index patient0" do
    before(:each) do
      get "/patients/#{@patient.id}/levels", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return all boxes for the level" do
      levels = JSON.parse(response.body)
      expect(levels[0]["boxes"].length).to eq(Level.find(levels[0]["id"]).boxes.count)
      expect(levels[1]["boxes"].length).to eq(Level.find(levels[1]["id"]).boxes.count)
    end

  end

end
