class Api::V1::TrainingSessionNoRawDataSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :duration, :screen_resolution_x, :screen_resolution_y, :tracker_type, :user_id, :patient_id, :type, :tracker_calibration_parameter, :audio_file

  def tracker_calibration_parameter
    Api::V1::TrackerCalibrationParameterSerializer.new(object.tracker_calibration_parameter)
  end
end
