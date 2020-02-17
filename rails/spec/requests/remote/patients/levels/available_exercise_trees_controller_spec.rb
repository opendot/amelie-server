require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::Levels::AvailableExerciseTreesController, :type => :request do
  include_context "signin"
  include_context "cognitive_session_utils"
  before(:all) do
      signin_researcher
  end

  context "index" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)

      @exercise_tree = ExerciseTree.first
      @user = @current_user
      
      # The test seeder doesn't create sessions, create them now
      @num_sessions = 2
      @num_sessions.times do |i|
        create_and_conclude_session( SecureRandom.uuid(), @exercise_tree, true)
      end

      get "/patients/#{@patient.id}/levels/#{@exercise_tree.level_id}/available_exercise_trees", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return only exercise of the selected level" do
      available_exercise_trees = JSON.parse(response.body)
      
      available_exercise_trees.each do |available_exercise_tree|
        expect(available_exercise_tree["exercise_tree"]["level_id"]).to eq(@exercise_tree.level_id)
      end
    end

  end

end
