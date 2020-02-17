require 'rails_helper'
require 'shared/signin.rb'
require 'shared/tree_utils.rb'

describe Api::V1::TrackerCalibrationParametersController, :type => :request do
  include_context "signin"
  include_context "tree_utils"
  before(:all) do
    signin_researcher
  end

  context "update" do
    before(:each) do
      @patient = Patient.last
      @current_user.add_patient(@patient)

      # The current tracker_calibration_parameter
      @last_tracker_calibration_parameter = @patient.tracker_calibration_parameter

      @tracker_calibration_param_hash = {
        transition_matrix: '"0.0063521 0.00520559 0.01847933 0.00456646", "0.00036145 0.0 0.0 0.0; 0.0 0.00044437 0.0 0.0; 0.0 0.0 0.00167195 0.0; 0.0 0.0 0.0 0.00029474"',
        trained_fixation_time: 12,
      }

      put "/patients/#{@patient.id}/tracker_calibration_parameters/last", params: @tracker_calibration_param_hash.to_json, headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "created a new object" do
      tracker_calibration_param = JSON.parse(response.body)
      expect(tracker_calibration_param["id"].length).to_not eq(@last_tracker_calibration_parameter.id)
    end

    it "didn't delete the previous tracker_calibration_param" do
      expect(TrackerCalibrationParameter.exists?(@last_tracker_calibration_parameter.id)).to be true
    end

    it "updated the given values" do
      tracker_calibration_param = JSON.parse(response.body)
      track = TrackerCalibrationParameter.find(tracker_calibration_param["id"])

      expect( track.transition_matrix).to eq(@tracker_calibration_param_hash[:transition_matrix])
      expect( track.trained_fixation_time).to eq(@tracker_calibration_param_hash[:trained_fixation_time])
    end

    it "kept the values of the previous tracker_calibration_param" do
      tracker_calibration_param = JSON.parse(response.body)
      track = TrackerCalibrationParameter.find(tracker_calibration_param["id"])

      expect( track.setting).to eq(@last_tracker_calibration_parameter.setting)
      expect( track.patient_id).to eq(@last_tracker_calibration_parameter.patient_id)
      expect( track.fixing_time_ms).to eq(@last_tracker_calibration_parameter.fixing_time_ms)
    end

    it "changed the tracker_calibration_param of the patient" do
      tracker_calibration_param = JSON.parse(response.body)
      expect(@patient.tracker_calibration_parameter.id).to eq(tracker_calibration_param["id"])
    end

  end

end