require 'rails_helper'
require 'shared/signin.rb'
require 'shared/cognitive_session_utils.rb'

describe Api::V1::Patients::WidgetsController, :type => :request do
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
        get "/patients/#{@patient.id}/widgets", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "contains cognitive and commuunication section" do
        widgets = JSON.parse(response.body)
        expect(widgets).to have_key("cognitive_sessions")
        expect(widgets).to have_key("communication_sessions")
      end
    end

    context "with type param" do
      before(:each) do
        @type = "cognitive_sessions"
        get "/patients/#{@patient.id}/widgets?type=#{@type}", headers: @headers
      end

      it "contains only section of the given type" do
        widgets = JSON.parse(response.body)
        expect(widgets).to have_key(@type)
      end

      it "doesn't contains other sections" do
        widgets = JSON.parse(response.body)
        expect(widgets.keys.length).to eq(1)
      end
    end

    context "cognitive_sessions" do
      before(:each) do
        get "/patients/#{@patient.id}/widgets?type=cognitive_sessions", headers: @headers
      end

      it "contains all levels in progress" do
        widgets = JSON.parse(response.body)
        expect(widgets["cognitive_sessions"]["progress"].length).to eq(Level.count)
      end
    end

    context "communication_sessions" do
      before(:each) do
        get "/patients/#{@patient.id}/widgets?type=communication_sessions", headers: @headers
      end

      it "return the number of communication sessions" do
        widgets = JSON.parse(response.body)
        expect(widgets["communication_sessions"]["sessions_count"]).to eq(CommunicationSession.where(patient: @patient).count)
      end
    end
    
  end

end
