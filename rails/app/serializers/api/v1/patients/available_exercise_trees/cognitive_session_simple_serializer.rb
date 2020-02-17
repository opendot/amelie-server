class Api::V1::Patients::AvailableExerciseTrees::CognitiveSessionSimpleSerializer < ActiveModel::Serializer
  attributes :id, :start_time,
    :success, :average_selection_speed_ms

  def success
    object.completed_session? && object.all_answers_are_correct?
  end

  def average_selection_speed_ms
    object.average_selection_speed_ms
  end
end
