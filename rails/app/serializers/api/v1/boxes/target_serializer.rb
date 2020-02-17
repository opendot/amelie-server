class Api::V1::Boxes::TargetSerializer < ActiveModel::Serializer
  attributes :id, :name, :published, :updated_at, :position
  has_many :exercise_trees, serializer: Api::V1::Targets::ListExerciseTreeSerializer 

  def position
    object.box_layout.position
  end
  
  def exercise_trees
    object.exercise_trees.base_params.with_position
  end

end