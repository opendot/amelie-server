class Api::V1::Patients::AvailableExerciseTrees::CognitiveSessionSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :screen_resolution_x, :screen_resolution_y,
    :tracker_type, :user_id, :patient_id, :type,
    :audio_file, :success, :average_selection_speed_ms
  has_one :tracker_calibration_parameter

  def audio_file
    unless object.audio_file.nil?
      Api::V1::AudioFileSerializer.new(object.audio_file)
    end
  end

  def success
    object.completed_session? && object.all_answers_are_correct?
  end

  def average_selection_speed_ms
    object.average_selection_speed_ms
  end
end
