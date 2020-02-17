class Widget
  # Resume of patient activity from all times

  attr_accessor :patient_id, :string

  def initialize(patient_id)
    self.patient_id = patient_id
  end

  def <=>(other)
    [patient_id] <=> [other.patient_id]
  end

  def cognitive_sessions
    {
      progress: self.progress,
      last_badge: self.last_badge ? Api::V1::BadgeSerializer.new(self.last_badge) : nil,
    }
  end

  def communication_sessions
    {
      sessions_count: self.sessions_count,
      average_selection_speed_ms: self.average_selection_speed_ms,
    }
  end

  # List of all levels with the total amount of exercise
  # and the number of completed exercises
  def progress
    Level.all.map do |level|
      {
        level_id: level.id,
        level_name: level.name,
        level_value: level.value,
        exercises_total: level.exercise_trees.count,
        exercises_completed: AvailableExerciseTree.for_patient(self.patient_id).complete
          .where(:exercise_tree_id => level.exercise_trees.ids).count,
      }
    end
  end

  # Last badge of the patient
  def last_badge
    Badge.for_patient(self.patient_id).reorder(date: :asc).last
  end

  # Number of communication sessions count
  def sessions_count
    CommunicationSession.where(patient_id: self.patient_id).count
  end

  # Average selection speed of the patient
  # calculated from all the sessions
  def average_selection_speed_ms
    tot = 0
    count = 0

    # Check all sessions of the patients
    # exclude sessions without patient choices
    TrainingSession.where(patient_id: self.patient_id)
      .with_patient_choices
      .each do |session|
      average_selection = session.average_selection_speed_ms
      if average_selection > 0
        tot += average_selection
        count += 1
      end
    end

    if count == 0
      return 0
    end

    return tot/count
  end

end