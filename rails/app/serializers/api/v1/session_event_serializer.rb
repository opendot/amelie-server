class Api::V1::SessionEventSerializer < ActiveModel::Serializer
  attributes :id, :type, :timestamp
end
