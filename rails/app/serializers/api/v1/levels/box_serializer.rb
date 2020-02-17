class Api::V1::Levels::BoxSerializer < ActiveModel::Serializer
  attributes :id, :name, :level_id, :published, :updated_at, :targets

  def targets
    object.box_layouts.as_target.with_exercise_trees_count
  end
end