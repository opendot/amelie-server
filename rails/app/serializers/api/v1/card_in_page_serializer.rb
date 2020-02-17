class Api::V1::CardInPageSerializer < ActiveModel::Serializer
  attributes :id, :label, :level, :type, :x_pos, :y_pos, :scale
  has_one :content, serializer: Api::V1::ContentSerializer
  has_many :card_tags, serializer: Api::V1::TagSerializer
end
