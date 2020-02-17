class Api::V1::Patients::DailyActivities::TrainingSessionSerializer < ActiveModel::Serializer
  attributes :id, :start_time, :type
end
