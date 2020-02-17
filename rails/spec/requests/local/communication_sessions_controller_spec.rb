require 'rails_helper'
require 'shared/signin.rb'

describe Api::V1::CommunicationSessionsController, :type => :request do
  include_context "signin"

  before(:all) do
    signin_researcher
    @patient = Patient.first
  end

  def post_communication_session(patient, tracker_params, id = SecureRandom.uuid())
    session = {
      id: id,
      patient_id: patient.id,
      tracker_calibration_parameter: {
        fixing_radius: tracker_params.fixing_radius,
        fixing_time_ms: tracker_params.fixing_time_ms,
        type: tracker_params.type,
      },
    }
    post "/communication_sessions", params: session.to_json, headers: @headers
  end

  context "create" do

    before(:each) do
      @tracker_params = @patient.tracker_calibration_parameter
    end

    context "badge creation" do

      context "normal sessions" do
        before(:each) do
          # Create fake sessions
          9.times do |i|
            post_communication_session(@patient, @tracker_params)
          end
        end

        it "didn't create any badge" do
          expect( Badge.for_patient(@patient.id).communication_count.limit(1).count).to eq(0)
        end

        it "create a badge at 10th communication session" do
          post_communication_session(@patient, @tracker_params)

          expect( Badge.for_patient(@patient.id).communication_count.count).to eq(1)
        end

        it "create a badge with the correct count value" do
          post_communication_session(@patient, @tracker_params)

          expect( Badge.for_patient(@patient.id).communication_count.first.count).to eq(10)
        end

        it "create other badges on next sessions" do
          91.times do |i|
            post_communication_session(@patient, @tracker_params)
          end
          counts = [10, 25, 50, 100]
          counts.each do |count|
            expect( Badge.for_patient(@patient.id).communication_count.where(count: count).count).to eq(1)
          end
        end
      end

      context "preview sessions" do
        before(:each) do
          # Create fake sessions
          9.times do |i|
            post_communication_session(@patient, @tracker_params, "preview_test")
          end
        end

        it "didn't create any badge" do
          expect( Badge.for_patient(@patient.id).communication_count.limit(1).count).to eq(0)
        end

        it "doesn't create a badge at 10th communication session" do
          post_communication_session(@patient, @tracker_params)

          expect( Badge.for_patient(@patient.id).communication_count.limit(1).count).to eq(0)
        end

        it "create a badge after 10 not-preview communication session" do
          9.times do |i|
            post_communication_session(@patient, @tracker_params)
          end

          expect( Badge.for_patient(@patient.id).communication_count.count).to eq(0)

          post_communication_session(@patient, @tracker_params, "preview_test_last")
          expect( Badge.for_patient(@patient.id).communication_count.count).to eq(0)

          post_communication_session(@patient, @tracker_params)
          expect( Badge.for_patient(@patient.id).communication_count.count).to eq(1)
        end
      end

    end

  end

end