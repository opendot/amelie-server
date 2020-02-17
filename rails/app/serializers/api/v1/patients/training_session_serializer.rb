class Api::V1::Patients::TrainingSessionSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :duration, :type, :average_selection_speed_ms

  def average_selection_speed_ms
    object.average_selection_speed_ms
  end

end
