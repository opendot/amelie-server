require 'rails_helper'
require 'shared/signin.rb'

RSpec.describe Api::V1::LevelsController, type: :request do
  include_context "signin"
  before(:all) do
    @current_user = User.find("testUser")
    signin_researcher
  end

  context "index" do
    before(:each) do
      # This route is available only in _remote environment
      get "/levels", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return boxes_count for the level" do
      levels = JSON.parse(response.body)
      expect(levels[0]["boxes_count"]).to eq(Level.find(levels[0]["id"]).boxes.count)
      expect(levels[1]["boxes_count"]).to eq(Level.find(levels[1]["id"]).boxes.count)
    end

  end

  context "show" do
    before(:each) do
      @level = Level.first
      get "/levels/#{@level.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return the level" do
      level = JSON.parse(response.body)
      expect(level["name"]).to eq(@level.name)
    end

  end

end
