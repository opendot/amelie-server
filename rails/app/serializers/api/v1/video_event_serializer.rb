class Api::V1::VideoEventSerializer < ActiveModel::Serializer
  attributes :id, :type, :page_id, :card_id
end
