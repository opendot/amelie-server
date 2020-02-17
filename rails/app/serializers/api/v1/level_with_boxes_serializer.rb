class Api::V1::LevelWithBoxesSerializer < ActiveModel::Serializer
  attributes :id, :name, :value, :boxes

  def boxes
    object.boxes.base_params.select(:published).with_targets_count
  end
end