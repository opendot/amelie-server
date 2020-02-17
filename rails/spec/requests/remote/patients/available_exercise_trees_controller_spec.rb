require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::AvailableExerciseTreesController, :type => :request do
  include_context "signin"
  include_context "cognitive_session_utils"
  before(:all) do
      signin_researcher
  end

  context "show" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)
      @user = @current_user
      @exercise_tree = ExerciseTree.first

      # The test seeder doesn't create sessions, create them now
      @num_sessions = 2
      @num_sessions.times do |i|
        create_and_conclude_session( SecureRandom.uuid(), @exercise_tree, true)
      end

      get "/patients/#{@patient.id}/available_exercise_trees/#{@exercise_tree.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "has cognitive sessions and the exercise tree" do
      available_exercise_tree = JSON.parse(response.body)
      expect(available_exercise_tree).to have_key("cognitive_sessions")
      expect(available_exercise_tree).to have_key("exercise_tree")
    end

    it "has all cognitive sessions" do
      available_exercise_tree = JSON.parse(response.body)
      expect(available_exercise_tree["cognitive_sessions"].length).to eq(@num_sessions)
    end

    it "has success and avereage selection speed for all cognitive sessions" do
      available_exercise_tree = JSON.parse(response.body)
      available_exercise_tree["cognitive_sessions"].each do |cognitive_session|
        expect(cognitive_session["success"]).to be true
        expect(cognitive_session["average_selection_speed_ms"]).to be > 1
      end
    end

    it "has presentation page and strong feedback page" do
      available_exercise_tree = JSON.parse(response.body)
      expect(available_exercise_tree["exercise_tree"]["presentation_page"]).to_not be nil
      expect(available_exercise_tree["exercise_tree"]["strong_feedback_page"]).to_not be nil
    end

  end


end
