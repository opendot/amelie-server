class Api::V1::Patients::DailyActivitySerializer < ActiveModel::Serializer
  attributes :patient_id, :date, :sessions, :badges

  def date
    object.date_string
  end

  def sessions
    object.sessions.map do |session| 
      case session.type
      when "CognitiveSession"
        Api::V1::Patients::DailyActivities::CognitiveSessionSerializer.new(session)
      when "CommunicationSession"
        Api::V1::Patients::DailyActivities::CommunicationSessionSerializer.new(session)
      else
        Api::V1::Patients::DailyActivities::TrainingSessionSerializer.new(session)
      end
    end
  end

  def badges
    ActiveModelSerializers::SerializableResource.new(object.badges, each_serializer: Api::V1::BadgeSerializer)
  end
  
end