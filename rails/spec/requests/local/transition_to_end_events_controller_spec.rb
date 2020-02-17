require 'rails_helper'
require 'shared/cognitive_session_utils.rb'
require 'shared/signin.rb'

describe Api::V1::TransitionToEndEventsController, :type => :request do
  include_context "cognitive_session_utils"
  include_context "signin"

  before(:all) do
    @user = User.find("testUser")
    @patient = Patient.order(:id).last
    signin_researcher
  end

  def message_disable_socket_transition_to_end
    "#{message_disable_socket} Comment TransitionToEndEvent.broadcast_transition_message"
  end

  context "on CognitiveSession success" do
    context "at first attempt" do
      before(:each) do
        # Create a fake session
        @exercise = ExerciseTree.first
        @session = create_cognitive_session "CognitiveSession1", @exercise

        # Answer all questions correctly
        answer_all_questions @session, @exercise, true

        event = {training_session_id: @session.id, page_id: nil}
        begin
          post "/transition_to_end_events",  params: event.to_json, headers: @headers
        rescue Redis::CannotConnectError
          raise message_disable_socket_transition_to_end
        end
      end

      it "return 201 CREATED" do
        expect(response).to have_http_status(:created)
      end

      it "created a TransitionToEndEvent" do
        expect(TransitionToEndEvent.where(training_session_id: @session.id)).to_not be_nil
        expect(@session.session_events.where(type: "TransitionToEndEvent").count).to eq(1)
      end

      it "completed the exercise for the given patient" do
        available_exercise_tree = @exercise.available_exercise_tree_for(@patient.id)
        expect(available_exercise_tree.status).to eq("complete")
        expect(available_exercise_tree.conclusions_count).to eq(1)
      end

    end

    context "not at first attempt" do
      before(:each) do
        @exercise = ExerciseTree.first

        # The first attempt is a failure
        create_and_conclude_session SecureRandom.uuid(), @exercise, false

        # Create a fake session
        @session = create_cognitive_session "CognitiveSession1", @exercise

        # Answer all questions correctly
        answer_all_questions @session, @exercise, true

        event = {training_session_id: @session.id, page_id: nil}
        begin
          post "/transition_to_end_events",  params: event.to_json, headers: @headers
        rescue Redis::CannotConnectError
          raise message_disable_socket_transition_to_end
        end
      end

      it "return 201 CREATED" do
        expect(response).to have_http_status(:created)
      end

      it "created a TransitionToEndEvent" do
        expect(TransitionToEndEvent.where(training_session_id: @session.id)).to_not be_nil
        expect(@session.session_events.where(type: "TransitionToEndEvent").count).to eq(1)
      end

      it "didn't completed the exercise for the given patient" do
        available_exercise_tree = @exercise.available_exercise_tree_for(@patient.id)
        expect(available_exercise_tree.status).to eq("available")
        expect(available_exercise_tree.conclusions_count).to eq(1)
      end

      it "completed the exercise for the given patient after the third success" do
        session2 = create_cognitive_session "CognitiveSession2", @exercise
        answer_all_questions session2, @exercise, true

        event = {training_session_id: session2.id, page_id: nil}
        begin
          post "/transition_to_end_events",  params: event.to_json, headers: @headers
        rescue Redis::CannotConnectError
          raise message_disable_socket_transition_to_end
        end

        expect(@exercise.available_exercise_tree_for(@patient.id).status).to eq("available")

        session3 = create_cognitive_session "CognitiveSession3", @exercise
        answer_all_questions session3, @exercise, true

        event = {training_session_id: session3.id, page_id: nil}
        begin
          post "/transition_to_end_events",  params: event.to_json, headers: @headers
        rescue Redis::CannotConnectError
          raise message_disable_socket_transition_to_end
        end

        expect(@exercise.available_exercise_tree_for(@patient.id).status).to eq("complete")
      end

    end

  end

  context "on CognitiveSession failed" do
    before(:each) do
      # Create a fake session
      @exercise = ExerciseTree.first
      @session = create_cognitive_session "CognitiveSession1", @exercise

      # Answer all questions wrongly
      answer_all_questions @session, @exercise, false

      event = {training_session_id: @session.id, page_id: nil}
      begin
        post "/transition_to_end_events",  params: event.to_json, headers: @headers
      rescue Redis::CannotConnectError
        raise message_disable_socket_transition_to_end
      end
    end

    it "return 201 CREATED" do
      expect(response).to have_http_status(:created)
    end

    it "created a TransitionToEndEvent" do
      expect(TransitionToEndEvent.where(training_session_id: @session.id)).to_not be_nil
      expect(@session.session_events.where(type: "TransitionToEndEvent").count).to eq(1)
    end

    it "didn't complete the exercise for the given patient" do
      expect(@patient.available_exercise_trees.where(exercise_tree: @exercise).first.status).to eq("available")
    end

    it "reset count in available_exercise_tree and available_box" do
      session2 = create_cognitive_session "CognitiveSession2", @exercise
      answer_all_questions session2, @exercise, true

      event = {training_session_id: session2.id, page_id: nil}
      begin
        post "/transition_to_end_events",  params: event.to_json, headers: @headers
      rescue Redis::CannotConnectError
        raise message_disable_socket_transition_to_end
      end

      expect(@exercise.available_exercise_tree_for(@patient.id).conclusions_count).to eq(1)
      expect(@exercise.available_box_for(@patient.id).current_exercise_tree_conclusions_count).to eq(1)

      session3 = create_cognitive_session "CognitiveSession3", @exercise
      answer_all_questions session3, @exercise, false

      event = {training_session_id: session3.id, page_id: nil}
      begin
        post "/transition_to_end_events",  params: event.to_json, headers: @headers
      rescue Redis::CannotConnectError
        raise message_disable_socket_transition_to_end
      end

      expect(@exercise.available_exercise_tree_for(@patient.id).conclusions_count).to eq(0)
      expect(@exercise.available_box_for(@patient.id).current_exercise_tree_conclusions_count).to eq(0)
    end

  end

  context "on CognitiveSession interrupted" do
    before(:each) do
      # Create a fake session
      @exercise = ExerciseTree.first
      @session = create_cognitive_session "CognitiveSession1", @exercise

      # Answer questions correctly, but don't answer the last question
      page = @exercise.root_page
      while !page.nil? do
        correct_layout = page.page_layouts.where(correct: true).first

        if correct_layout.nil?
          # This should never happen
          page = nil
        else
          # Select the correct answer
          next_page_id = correct_layout.next_page_id
          PatientEyeChoiceEvent.create!(training_session: @session, page_id: page.id, card_id: correct_layout.card_id)

          if next_page_id.nil?
            # Delete the last choice
            @session.session_events.where(type: "PatientEyeChoiceEvent").order(:created_at).last.destroy
            @session.session_events.where(type: "TransitionToPageEvent").order(:created_at).last.destroy
            page = nil
          else
            next_page_event = TransitionToPageEvent.new(training_session: @session,
              page: page, card_id: correct_layout.card_id, next_page_id: next_page_id)
            next_page_event.skip_broadcast_callback = true
            next_page_event.save!
            page = Page.find(next_page_id)
          end
        end
      end

      event = {training_session_id: @session.id, page_id: nil}
      begin
        post "/transition_to_end_events",  params: event.to_json, headers: @headers
      rescue Redis::CannotConnectError
        raise message_disable_socket_transition_to_end
      end
    end

    it "return 201 CREATED" do
      expect(response).to have_http_status(:created)
    end

    it "created a TransitionToEndEvent" do
      expect(TransitionToEndEvent.where(training_session_id: @session.id)).to_not be_nil
      expect(@session.session_events.where(type: "TransitionToEndEvent").count).to eq(1)
    end

    it "didn't complete the exercise for the given patient" do
      expect(@exercise.available_exercise_tree_for(@patient.id).status).to eq("available")
    end

  end
end
