require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::DailyActivitiesController, :type => :request do
  include_context "signin"
  include_context "cognitive_session_utils"

  before(:all) do
      signin_parent
  end

  context "index" do
    before(:each) do
      @patient = Patient.first
      @patient.update!(created_at: DateTime.new(2010, 1, 26))
      @current_user.add_patient(@patient)

      @from = 25.days.ago.utc.strftime("%d-%m-%Y")# "01-01-2011"
      @to = 2.days.ago.utc.strftime("%d-%m-%Y")# "12-07-2011"
      @date = 20.days.ago.at_beginning_of_day

      # create fake events
      @user = @current_user
      @target = Level.first.boxes.first.targets.first

      # more than 1 month ago
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 2.months.ago.at_beginning_of_day)

      # range from
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: @date)
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.to_a[1], true).update!(start_time: @date)
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 16.days.ago.at_beginning_of_day)
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 10.days.ago.at_beginning_of_day)
      # range to

      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 1.day.ago.at_beginning_of_day)

      # Also, update the existing badges date, put them in the from-to range
      Badge.for_patient(@patient.id).update_all(date: 3.days.ago)
    end

    context "without dates" do
      before(:each) do
        get "/patients/#{@patient.id}/daily_activities", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end
  
      it "return the list of days with activities in the last month" do
        daily_activities = JSON.parse(response.body)
        expect(daily_activities.length).to eq(5)
      end

      it "return the date in format dd-mm-yyyy" do
        daily_activities = JSON.parse(response.body)
        expect(daily_activities[0]["date"]).to eq(20.days.ago.utc.strftime("%d-%m-%Y"))
      end

      it "return the sessions count" do
        daily_activities = JSON.parse(response.body)
        expect(daily_activities[0]["sessions_count"]).to eq(2)
      end

    end

    context "with from-to dates" do
      before(:each) do
        get "/patients/#{@patient.id}/daily_activities?from_date=#{@from}&to_date=#{@to}", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end
  
      it "return the list of days with activities in the given dates" do
        daily_activities = JSON.parse(response.body)
        expect(daily_activities.length).to eq(4)
      end

    end

    context "ability" do
      context "Researcher" do
        before(:each) do
          User.find(@current_user.id).update!(type: "Researcher")
          @current_user.patients.delete_all
          get "/patients/#{@patient.id}/daily_activities", headers: @headers
        end

        it "can access all patients" do
          daily_activities = JSON.parse(response.body)
          expect(daily_activities.length).to eq(5)
        end
      end

      context "Superadmin" do
        before(:each) do
          User.find(@current_user.id).update!(type: "Superadmin")
          @current_user.patients.delete_all
          get "/patients/#{@patient.id}/daily_activities", headers: @headers
        end

        it "can access all patients" do
          daily_activities = JSON.parse(response.body)
          expect(daily_activities.length).to eq(5)
        end
      end

    end
    
  end

  context "show" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)

      # Reload info, other tests may influence this one
      @current_user.reload

      @date = 20.days.ago.at_beginning_of_day.strftime("%d-%m-%Y")
      @num_badges = 4

      # create fake events
      @user = @current_user
      @target = Level.first.boxes.first.targets.first

      # on another day
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: 2.months.ago.at_beginning_of_day)

      # on date
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.first, true).update!(start_time: @date)
      create_and_conclude_session( SecureRandom.uuid(), @target.exercise_trees.to_a[1], true).update!(start_time: @date)
      Badge.for_patient(@patient.id).limit(@num_badges).update_all(date: @date.to_datetime)

      get "/patients/#{@patient.id}/daily_activities/#{@date}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return all sessions of the given date" do
      daily_activity = JSON.parse(response.body)
      expect(daily_activity["sessions"].length).to eq(2)
    end

    it "return all badges of the given date" do
      daily_activity = JSON.parse(response.body)
      expect(daily_activity["badges"].length).to eq(@num_badges)
    end

  end

end
