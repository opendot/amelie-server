require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::TrainingSessionsController, :type => :request do
  include_context "signin"
  include_context "cognitive_session_utils"
  before(:all) do
    signin_researcher
  end

  context "index" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)
      @user = @current_user
      @exercise_tree = ExerciseTree.first

      # The test seeder doesn't create sessions, create them now
      @num_sessions = 2
      @num_sessions.times do |i|
        s = create_and_conclude_session( SecureRandom.uuid(), @exercise_tree, true)
        s.update!(start_time: i.hours.ago)
        s.reload
      end

      
    end

    context "training_sessions" do
      before(:each) do
        get "/patients/#{@patient.id}/training_sessions", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return all sessions" do
        sessions = JSON.parse(response.body)
        expect(sessions.length).to eq(TrainingSession.for_patient(@patient.id).count)
      end
    end

    context "cognitive_sessions" do
      before(:each) do
        get "/patients/#{@patient.id}/cognitive_sessions", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return all cognitive sessions" do
        sessions = JSON.parse(response.body)
        expect(sessions.length).to eq(CognitiveSession.for_patient(@patient.id).count)
      end
    end

    context "communication_sessions" do
      before(:each) do
        get "/patients/#{@patient.id}/communication_sessions", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end
      
      it "return all communication sessions" do
        sessions = JSON.parse(response.body)
        expect(sessions.length).to eq(CommunicationSession.for_patient(@patient.id).count)
      end
    end

    context "order" do

      context "duration" do
        before(:each) do
          get "/patients/#{@patient.id}/training_sessions?order=duration", headers: @headers
        end

        it "return sorted by duration" do
          sessions = JSON.parse(response.body)
          prev_session = nil

          sessions.each do |session|
            unless prev_session.nil?
              expect(session["duration"].to_f).to be >= prev_session["duration"].to_f
            end

            prev_session = session
          end
        end
  
      end

      context "duration DESC" do
        before(:each) do
          get "/patients/#{@patient.id}/training_sessions?order=duration&direction=DESC", headers: @headers
        end

        it "return sorted by duration" do
          sessions = JSON.parse(response.body)
          prev_session = nil

          sessions.each do |session|
            unless prev_session.nil?
              expect(session["duration"].to_f).to be <= prev_session["duration"].to_f
            end

            prev_session = session
          end
        end
  
      end

      context "start_time DESC" do
        before(:each) do
          get "/patients/#{@patient.id}/training_sessions?order=start_time&direction=DESC", headers: @headers
        end

        it "return sorted by start_time" do
          sessions = JSON.parse(response.body)
          prev_session = nil

          sessions.each do |session|
            unless prev_session.nil?
              expect(session["start_time"].to_datetime.to_i).to be <= prev_session["start_time"].to_datetime.to_i
            end

            prev_session = session
          end
        end
  
      end

    end

  end

  context "show" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)
      @user = @current_user
      @exercise_tree = ExerciseTree.first

      # The test seeder doesn't create sessions, create them now
      @session = create_and_conclude_session( SecureRandom.uuid(), @exercise_tree, true)
    end

    context "patient session" do

      context "training_sessions" do
        before(:each) do
          get "/patients/#{@patient.id}/training_sessions/#{@session.id}", headers: @headers
        end

        it "return 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "return the session" do
          session = JSON.parse(response.body)
          expect(session["id"]).to eq(@session.id)
        end

        it "return the selection speed in milliseconds" do
          session = JSON.parse(response.body)
          expect(session["average_selection_speed_ms"]).to be > 1
        end

        it "return the duration in seconds" do
          session = JSON.parse(response.body)
          expect(session["duration"]).to be > 0
        end
      end

      context "cognitive_sessions" do
        before(:each) do
          get "/patients/#{@patient.id}/cognitive_sessions/#{@session.id}", headers: @headers
        end

        it "return 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "return steps array for cognitive sessions" do
          session = JSON.parse(response.body)
          expect(session["steps"].length).to eq(@exercise_tree.root_page.subtree.count)
        end
      end

      context "communication_sessions" do
        before(:each) do
          get "/patients/#{@patient.id}/communication_sessions/#{@session.id}", headers: @headers
        end

        it "return 404 NOT_FOUND if the type is wrong" do
          expect(response).to have_http_status(:not_found)
        end
      end

    end

  end

end
