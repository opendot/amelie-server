class Api::V1::Patients::AvailableExerciseTrees::PageSerializer < ActiveModel::Serializer
  attributes :id, :name, :level, :background_color, :cards

  def cards
    ActiveModelSerializers::SerializableResource.new(object.page_layouts, each_serializer: Api::V1::Patients::AvailableExerciseTrees::CardLayoutSerializer)
  end

  def level
    object.depth
  end
end
