require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::StatsController, :type => :request do
  include_context "signin"
  include_context "cognitive_session_utils"

  before(:all) do
      signin_researcher
  end

  context "index" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)
    end

    context "without params" do
      before(:each) do
        get "/patients/#{@patient.id}/stats", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "contains cognitive and commuunication section" do
        stats = JSON.parse(response.body)
        expect(stats).to have_key("cognitive_sessions")
        expect(stats).to have_key("communication_sessions")
      end

      it "return datas for the last 10 days" do
        stats = JSON.parse(response.body)
        expect(stats["communication_sessions"]["count"]["data"].length).to eq(10)
        expect(stats["cognitive_sessions"]["count"]["data"].length).to eq(10)
      end

    end

    context "with type param" do
      before(:each) do
        @type = "cognitive_sessions"
        get "/patients/#{@patient.id}/stats?type=#{@type}", headers: @headers
      end

      it "contains only section of the given type" do
        stats = JSON.parse(response.body)
        expect(stats).to have_key(@type)
      end

      it "doesn't contains other sections" do
        stats = JSON.parse(response.body)
        expect(stats.keys.length).to eq(1)
      end
    end

    context "cognitive_sessions" do
      before(:each) do
        @days_amount = 6
        get "/patients/#{@patient.id}/stats?type=cognitive_sessions&days=#{@days_amount}", headers: @headers

        @stats = JSON.parse(response.body)
      end

      it "contains all levels in progress" do
        expect(@stats["cognitive_sessions"]["count"]["count"]).to eq(0)
      end

      it "return an object for every day" do
        expect(@stats["cognitive_sessions"]["correct_answers"]["data"].length).to eq(@days_amount)
      end
    end

    context "communication_sessions" do
      before(:each) do
        @days_amount = 6
        get "/patients/#{@patient.id}/stats?type=communication_sessions&days=#{@days_amount}", headers: @headers

        @stats = JSON.parse(response.body)
      end

      it "return the number of communication sessions" do
        expect(@stats["communication_sessions"]["count"]["count"]).to eq(0)
      end

      it "return an object for every day" do
        expect(@stats["communication_sessions"]["count"]["data"].length).to eq(@days_amount)
      end
    end

    context "correct_answers" do
      before(:each) do
        # create fake events
        @user = @current_user
        @target = Level.first.boxes.first.targets.first

        @percentage = 4.0/5.0
        # Outside span
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, false).update!(start_time: 30.days.ago)

        # Previous time span
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 12.days.ago)

        # Current time span
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 9.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.to_a[1], false).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 3.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 1.days.ago)

        get "/patients/#{@patient.id}/stats", headers: @headers
        @stats = JSON.parse(response.body)
        @correct_answers = @stats["cognitive_sessions"]["correct_answers"]

      end

      it "return the percentage of correct answers" do
        expect(@correct_answers["percentage"]).to eq(@percentage)
      end

      it "return the difference of percentage with the previous span" do
        expect(@correct_answers["difference"]).to eq(@percentage - 1)
      end

      it "return the percentage for every day" do
        days_with_answers = [0, 3, 6, 8]
        @correct_answers["data"].each_with_index do |data, index|
          if days_with_answers.include?(index)
            if index == 3
              expect(data["percentage"]).to eq(0.5)
            else
              expect(data["percentage"]).to eq(1)
            end
          else
            expect(data["percentage"]).to be_nil
          end
        end
      end

    end

    context "count" do
      before(:each) do
        # create fake events
        @user = @current_user
        @target = Level.first.boxes.first.targets.first

        # Current time span
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 9.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.to_a[1], false).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 3.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 1.days.ago)

        get "/patients/#{@patient.id}/stats", headers: @headers
        @stats = JSON.parse(response.body)
        @count = @stats["cognitive_sessions"]["count"]
      end

      it "return the amount of cognitive sessions" do
        expect(@count["count"]).to eq(5)
      end

      it "return the average amount of sessions per day" do
        # 3 days with 1 session and 1 day with 2 sessions
        average = ( 1*3 + 2*1 + 6*0).to_f/10
        expect(@count["average"]).to eq(average)
      end

      it "return the session count for every day" do
        days_with_answers = [0, 3, 6, 8]
        @count["data"].each_with_index do |data, index|
          if days_with_answers.include?(index)
            if index == 3
              expect(data["count"]).to eq(2)
            else
              expect(data["count"]).to eq(1)
            end
          else
            expect(data["count"]).to eq(0)
          end
        end
      end

    end

    context "average_selection_speed" do
      before(:each) do
        # create fake events
        @user = @current_user
        @target = Level.first.boxes.first.targets.first

        # Outside span
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, false).update!(start_time: 30.days.ago)

        # Previous time span
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 12.days.ago)

        # Current time span
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 9.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.to_a[1], false).update!(start_time: 6.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 3.days.ago)
        create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 1.days.ago)

        get "/patients/#{@patient.id}/stats", headers: @headers
        @stats = JSON.parse(response.body)
        @average_selection_speed = @stats["cognitive_sessions"]["average_selection_speed"]
      end

      it "return the percentage of correct answers" do
        expect(@average_selection_speed["millis"]).to be > 0
      end

      it "return the difference of percentage with the previous span" do
        expect(@average_selection_speed["difference"]).to_not be nil
      end

      it "return the percentage for every day" do
        days_with_answers = [0, 3, 6, 8]
        @average_selection_speed["data"].each_with_index do |data, index|
          if days_with_answers.include?(index)
            expect(data["millis"]).to be > 0
          else
            expect(data["millis"]).to be 0
          end
        end
      end

    end
    
  end

end
