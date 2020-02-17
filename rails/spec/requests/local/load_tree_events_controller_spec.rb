require 'rails_helper'
require 'shared/cognitive_session_utils.rb'
require 'shared/signin.rb'

RSpec.describe Api::V1::LoadTreeEventsController, type: :request do
  include_context "cognitive_session_utils"
  include_context "signin"
  
  before(:all) do
    @user = User.find("testUser")
    @patient = Patient.order(:id).last
    signin_researcher
  end

  def message_disable_socket_transition_to_page
    "#{message_disable_socket} Comment TransitionToPageEvent.broadcast_transition_message"
  end

  def post_load_tree_events event
    begin
      post "/load_tree_events", params: event.to_json, headers: @headers
    rescue JSON::ParserError
      raise message_disable_socket_transition_to_page
    end
  end

  describe "create" do
    before(:each) do
      @exercise = ExerciseTree.first
      @session = create_only_cognitive_session "CognitiveSession1"
    end

    it "return 201" do
      event = {
        training_session_id: @session.id,
        tree: {
          id: @exercise.id,
        },
      }

      post_load_tree_events event

      expect(response).to have_http_status(:created)
    end

    it "return 422 if tree_id is null" do
      event = {
        training_session_id: @session.id,
        tree: {
          id: nil,
        },
      }


      post "/load_tree_events", params: event.to_json, headers: @headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "return error message if tree_id is null" do
      event = {
        training_session_id: @session.id,
        tree: {
          id: nil,
        },
      }

      post "/load_tree_events", params: event.to_json, headers: @headers
      body = JSON.parse(response.body)

      expect(body["errors"].length).to eq(1)
      expect(body["errors"][0]).to eq(I18n.t("error_load_tree_missing_exercise_tree"))
    end

  end

  describe "new CognitiveSession after a completed CognitiveSession" do
    before(:each) do
      # Create a previous CognitiveSession
      @exercise = ExerciseTree.first
      correct = true
      create_and_conclude_session "CognitiveSession1", @exercise, correct
      @exercise.completed_by @patient, correct

      # Create a new session
      @session = create_only_cognitive_session "CognitiveSession2"
      @event = {
        training_session_id: @session.id,
        tree: {
          id: @exercise.id,
        },
      }
    end

    it "can't repeat ExerciseTree in the same day" do
      post_load_tree_events @event
      expect(response).to have_http_status(:unauthorized)
      expect(@session.session_events.count).to eq(0)
    end

    it "return 201" do
      allow_to_repeat_exercise @exercise, @patient

      post_load_tree_events @event
      expect(response).to have_http_status(:created)
    end

  end

  describe "new CognitiveSession after an interrupted CognitiveSession" do
    before(:each) do
      # Create a previous interrupted CognitiveSession
      @exercise = ExerciseTree.first
      create_and_interrupt_session "CognitiveSession1", @exercise, 1

      # Create a new session
      @session = create_only_cognitive_session "CognitiveSession2"
      @event = {
        training_session_id: @session.id,
        tree: {
          id: @exercise.id,
        },
      }
    end

    it "can start a new CognitiveSession the same day" do
      post_load_tree_events @event
      expect(response).to have_http_status(:created)
    end

    it "didn't update the AvailableBox" do
      post_load_tree_events @event

      available_box = @exercise.available_box_for @patient.id
      expect(available_box.last_completed_exercise_tree_at).to be_nil
      expect(available_box.current_exercise_tree_conclusions_count).to eq(0)
    end
  end
end
