class Api::V1::Patients::DailyActivities::CognitiveSessionSerializer < Api::V1::Patients::DailyActivities::TrainingSessionSerializer
  attributes :exercise_tree

  def exercise_tree
    Api::V1::Patients::DailyActivities::ExerciseTreeSerializer.new(object.tree)
  end
end
