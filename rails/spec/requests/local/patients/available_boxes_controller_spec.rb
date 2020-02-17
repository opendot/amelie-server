require 'rails_helper'
require 'shared/signin.rb'

RSpec.describe Api::V1::Patients::AvailableBoxesController, type: :request do
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
      get "/patients/#{@patient.id}/available_boxes?page=1", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return all boxes" do
      boxes = JSON.parse(response.body)
      expect(boxes.length).to eq(Box.count)
    end

    it "return all boxes inside their level" do
      boxes = JSON.parse(response.body)
      level_ids = []
      box_ids = []
      
      boxes.each do |box|
        box_db = Box.find_by(id: box["box_id"])
        expect(box_db).to_not be_nil
        unless level_ids.include? box["level_id"]
          level_ids << box["level_id"]
        end
        # check if a box is duplicated
        expect(box_ids.include? box["box_id"]).to be false
        box_ids << box["box_id"]

        # check if the box is in the correct level
        expect(Level.find(box["level_id"]).boxes.where(id: box["box_id"]).count).to eq(1)
      end

      # Check that I have the correct number of levels
      # expect(level_ids.length).to eq(Level.with_one_or_more_boxes.count)
      # expect(box_ids.length).to eq(Box.count)

    end


  end

  context "index patient0with soft delete" do
    before(:each) do
      Box.first.destroy!
      get "/patients/#{@patient.id}/available_boxes?page=1", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return all boxes" do
      boxes = JSON.parse(response.body)
      expect(boxes.length).to eq(Box.count)
    end

    it "doesn't return deleted boxes" do
      boxes = JSON.parse(response.body)
      expect(boxes.length).to eq(Box.with_deleted.count-1)
    end

  end

  context "index patient0 with disabled user" do
    before(:each) do
      @patient.update!(disabled: true)
      get "/patients/#{@patient.id}/available_boxes?page=1", headers: @headers
    end

    it "return 403 FORBIDDEN" do
      expect(response).to have_http_status(:forbidden)
    end

  end

end
