class Api::V1::Patients::Levels::AvailableExerciseTreeSerializer < ActiveModel::Serializer
  attributes :completed, :in_progress,
    :cognitive_sessions
  
  has_one :exercise_tree, serializer: Api::V1::Patients::DailyActivities::ExerciseTreeSerializer
  
  def completed
    object.complete?
  end

  def in_progress
    # Check if there are sessions for this exercise_tree
    CognitiveSession.where(patient_id: object.patient_id)
    .with_tree(object.exercise_tree_id).limit(1).count > 0
  end

  def cognitive_sessions
    object.cognitive_sessions.map do |cognitive_session|
      Api::V1::Patients::AvailableExerciseTrees::CognitiveSessionSimpleSerializer.new(cognitive_session)
    end
  end

end
