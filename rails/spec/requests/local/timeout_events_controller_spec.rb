require 'rails_helper'
require 'shared/cognitive_session_utils.rb'
require 'shared/signin.rb'

RSpec.describe Api::V1::TimeoutEventsController, type: :request do
  include_context "cognitive_session_utils"
  include_context "signin"
  
  before(:all) do
    @user = User.find("testUser")
    @patient = Patient.order(:id).last
    signin_researcher
  end

  def message_disable_socket_transition_to_presentation
    "#{message_disable_socket} Comment TransitionToPresentationPageEvent.broadcast_transition_message"
  end

  def post_timeout_events event
    begin
      post "/timeout_events", params: event.to_json, headers: @headers
    rescue JSON::ParserError
      raise message_disable_socket_transition_to_presentation
    end
  end

  context "create" do
    before(:each) do
      # Create a fake session
      @exercise = ExerciseTree.first
      @session = create_cognitive_session "CognitiveSession1", @exercise

    end

    it "return 201 CREATED" do
      event = {training_session_id: @session.id, page_id: @exercise.root_page_id}
      post_timeout_events event
      expect(response).to have_http_status(:created)
    end

    it "return a TimeoutEvent with only id and type" do
      event = {training_session_id: @session.id, page_id: @exercise.root_page_id}
      post_timeout_events event
      timeout_event_created = JSON.parse(response.body)

      expect(timeout_event_created["id"]).to_not be_nil
      expect(timeout_event_created["type"]).to eq("TimeoutEvent")
      expect(timeout_event_created["training_session_id"]).to be_nil
      expect(timeout_event_created["page_id"]).to be_nil
      expect(timeout_event_created["card_id"]).to be_nil
      expect(timeout_event_created["next_page_id"]).to be_nil
    end

    it "return 422 UNPROCESSABLE ENTITY if page_id is missing" do
      event = {training_session_id: @session.id, page_id: nil}
      post_timeout_events event
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

end