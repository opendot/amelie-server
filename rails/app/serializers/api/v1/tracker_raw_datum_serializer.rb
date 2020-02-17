class Api::V1::TrackerRawDatumSerializer < ActiveModel::Serializer
  attributes :id, :timestamp, :x_position, :y_position
end
