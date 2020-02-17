class Api::V1::Patients::TrainingSessionDetailedSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :duration, :average_selection_speed_ms, :number_of_levels,:screen_resolution_x, :screen_resolution_y, :audio_file, :tracker_calibration_parameter

  def average_selection_speed_ms
    object.average_selection_speed_ms
  end

  def number_of_levels
    object.tree.max_page_depth + 1
  end


end
