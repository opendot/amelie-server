class Api::V1::PageSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :level, :background_color, :cards
  has_many :page_tags, serializer: Api::V1::TagSerializer

  def cards
    ActiveModelSerializers::SerializableResource.new(object.page_layouts, each_serializer: Api::V1::CardLayoutSerializer)
  end

  def level
    object.depth
  end
end
