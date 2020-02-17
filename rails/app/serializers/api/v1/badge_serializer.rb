class Api::V1::BadgeSerializer < ActiveModel::Serializer
  attributes :id, :patient_id, :date, :achievement, :target_id, :target_name, :box_id, :box_name, :level_id, :level_name, :count
end
