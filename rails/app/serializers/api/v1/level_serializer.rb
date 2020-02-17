class Api::V1::LevelSerializer < ActiveModel::Serializer
  attributes :id, :name, :value, :available, :boxes

  def boxes
    object.b
  end
end