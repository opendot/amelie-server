require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::AvailableLevelsController, :type => :request do
  include_context "signin"
  include_context "cognitive_session_utils"
  before(:all) do
      signin_researcher
  end

  context "index" do
    before(:each) do
      @patient = Patient.find("patient1")
      @current_user.add_patient(@patient)
    end

    context "without params" do
      before(:each) do
        # create fake events
        @user = @current_user
        @level = Level.first
        @target = @level.boxes.last.targets.first

        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 9.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.to_a[1], false).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 3.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 1.days.ago)

        get "/patients/#{@patient.id}/available_levels", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return an object for every level" do
        available_levels = JSON.parse(response.body)
        expect(available_levels.length).to eq(Level.count)
      end

      context "exercise_trees" do
        before(:each) do
          @available_levels = JSON.parse(response.body)
          @exercise_trees = @available_levels[0]["exercise_trees"]
        end

        it "return the total number of exercise" do
          expect(@exercise_trees["total"]).to eq(@level.exercise_trees.count)
        end

        it "return the number of completed exercise" do
          # In the seeder, patient1 completes the first 3 targets
          expect(@exercise_trees["completed"]).to eq(9)
        end

        it "return the number of ongoing exercise" do
          # With the fake events, I've started an exercise, but didn't conclude it
          expect(@exercise_trees["ongoing"]).to eq(1)
        end

      end

      context "correct_answers" do
        before(:each) do
          @available_levels = JSON.parse(response.body)
          @correct_answers = @available_levels[0]["correct_answers"]
        end

        it "return the percentage of correct answers" do
          expect(@correct_answers).to eq(0.8)
        end

      end

      context "average_selection_speed_ms" do
        before(:each) do
          @available_levels = JSON.parse(response.body)
          @average_selection_speed_ms = @available_levels[0]["average_selection_speed_ms"]
        end

        it "return the percentage of correct answers" do
          expect(@average_selection_speed_ms).to be > 0
        end

      end

    end

  end


end
