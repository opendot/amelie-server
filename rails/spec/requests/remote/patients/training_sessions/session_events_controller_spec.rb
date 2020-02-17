require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::TrainingSessions::SessionEventsController, :type => :request do
  include_context "signin"
  include_context "cognitive_session_utils"
  before(:all) do
    signin_researcher
  end

  context "index" do
    before(:each) do
      @patient = Patient.first
      # Researcher can access any patient
      @user = @current_user
      @exercise_tree = ExerciseTree.first

      # The test seeder doesn't create sessions, create them now
      @session = create_and_conclude_session( SecureRandom.uuid(), @exercise_tree, true)
    end

    context "training_sessions" do
      before(:each) do
        get "/patients/#{@patient.id}/training_sessions/#{@session.id}/session_events", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return all session events" do
        session_events = JSON.parse(response.body)
        expect(session_events.length).to eq(@session.session_events.count)
      end

      it "return id, type and timestamp params for all events" do
        session_events = JSON.parse(response.body)
        session_events.each do |event|
          expect(event).to have_key("id")
          expect(event).to have_key("type")
          expect(event).to have_key("timestamp")
        end
      end

      it "return tree_id param only for LoadTreeEvent" do
        session_events = JSON.parse(response.body)
        session_events.each do |event|
          if event["type"] == "LoadTreeEvent"
            expect(event).to have_key("tree_id")
          else
            expect(event).to_not have_key("tree_id")
          end
        end
      end

      it "return page_id, card_id params for PatientChoiceEvent" do
        session_events = JSON.parse(response.body)
        session_events.each do |event|
          if event["type"] == "PatientEyeChoiceEvent"
            expect(event).to have_key("page_id")
            expect(event).to have_key("card_id")
          end
        end
      end

      it "return next_page_id param for TransitionToPageEvent" do
        session_events = JSON.parse(response.body)
        session_events.each do |event|
          if event["type"] == "TransitionToPageEvent"
            expect(event).to have_key("next_page_id")
          end
        end
      end
    end

    context "communication_sessions" do
      before(:each) do
        get "/patients/#{@patient.id}/communication_sessions/#{@session.id}/session_events", headers: @headers
      end

      it "return 404 NOT FOUND, route is not available, use /patients/training_sessions/session_events" do
        expect(response).to have_http_status(:not_found)
      end
      
    end

  end

end
