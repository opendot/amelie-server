class Api::V1::Patients::AvailableLevelSerializer < ActiveModel::Serializer
  attributes :level_id, :level_name, :level_value,
    :exercise_trees, :correct_answers, :average_selection_speed_ms
  
  def exercise_trees
    {
      total: object.level.exercise_trees.count,
      completed: object.completed_available_exercise_trees.count,
      ongoing: object.ongoing_available_exercise_trees.count,
    }
  end

  def correct_answers
    object.correct_answers_percentage
  end

  def average_selection_speed_ms
    object.average_selection_speed_ms
  end

end
