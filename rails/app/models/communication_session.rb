class CommunicationSession < TrainingSession
  after_create :create_badge_sessions_count

  scope :not_preview, -> {where.not("id LIKE 'preview_%'")}

  # Create a Badge after a certain amount of CommunicationSession are started for the patient
  def create_badge_sessions_count
    count = CommunicationSession.where(patient_id: self.patient_id).not_preview.count
    if Badge.create_communication_count_badges?(count)
      Badge.create!(patient: self.patient, achievement: "communication_count", count: count)
    end
  end

end
