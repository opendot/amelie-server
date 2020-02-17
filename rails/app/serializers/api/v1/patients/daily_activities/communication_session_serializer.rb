class Api::V1::Patients::DailyActivities::CommunicationSessionSerializer < Api::V1::Patients::DailyActivities::TrainingSessionSerializer
  attributes :tree

  def tree
    object.tree
  end
end
