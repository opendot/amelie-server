require 'rails_helper'
require 'shared/signin.rb'

describe Api::V1::Patients::BadgesController, type: :request do
  include_context "signin"

  before(:all) do
    signin_researcher
  end

  context "index" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)
    end

    context "default" do
      before(:each) do
        get "/patients/#{@patient.id}/badges", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return a list of badges" do
        badges = JSON.parse(response.body)
        badges.each do |badge|
          expect(badge).to have_key("achievement")
          expect(badge).to have_key("date")
          expect(badge).to have_key("level_name")
        end
      end

    end

    context "accept per_page param" do
      before(:each) do
        @per_page = 3
        get "/patients/#{@patient.id}/badges?per_page=#{@per_page}", headers: @headers
      end

      it "return only a the first N badges" do
        badges = JSON.parse(response.body)
        expect(badges.length).to eq(@per_page)
      end

    end

    context "accept limit param" do
      before(:each) do
        @limit = 3
        get "/patients/#{@patient.id}/badges?limit=#{@limit}", headers: @headers
      end

      it "return only the last N badges" do
        badges = JSON.parse(response.body)
        expect(badges.length).to eq(@limit)
      end

      it "return the badges ordered by date descendant" do
        badges = JSON.parse(response.body)
        prev_badge = nil

        badges.each do |badge|
            unless prev_badge.nil?
              expect(badge["date"].to_datetime.to_i).to be <= prev_badge["date"].to_datetime.to_i
            end

            prev_badge = badge
          end
      end

    end

    context "accept type cognitive_sessions param" do
      before(:each) do
        get "/patients/#{@patient.id}/badges?type=cognitive_sessions", headers: @headers
      end

      it "return only badges related to cognitive sessions" do
        badges = JSON.parse(response.body)
        badges.each do |badge|
          expect(Badge.cognitive_session_achievements.include?(badge["achievement"])).to be true
        end
      end
    end

    context "accept type communication_sessions param" do
      before(:each) do
        get "/patients/#{@patient.id}/badges?type=communication_sessions", headers: @headers
      end

      it "return only badges related to communication sessions" do
        badges = JSON.parse(response.body)
        badges.each do |badge|
          expect(Badge.communication_session_achievements.include?(badge["achievement"])).to be true
        end
      end
    end

  end

end
