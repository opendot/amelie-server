class Api::V1::Patients::DailyActivities::ExerciseTreeSerializer < ActiveModel::Serializer
  attributes :id, :name, :exercise_tree_position,
    :target_id, :target_name, :target_position, :box_id, :box_name,
    :level_id, :level_name, :level_value
end
