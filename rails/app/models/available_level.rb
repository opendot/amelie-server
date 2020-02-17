class AvailableLevel < ApplicationRecord
  include ParanoidSynchronizable
  # Used to track if a Patient has completed a Level

  before_save :default_values
  after_create :calculate_status
  
  belongs_to :patient, optional: false
  belongs_to :level

  enum status: { available: 0, complete: 1, unavailable: 2 }

  validates :patient, uniqueness: { scope: :level }

  delegate :name, :surname, :birthdate, to: :patient, prefix: true
  delegate :name, :value, to: :level, prefix: true

  scope :updated_at_least_once, -> {where.not(updated_at: DateTime.new(1969,1,1,0,0,0).in_time_zone)}

  def default_values
    # We should use the 2 columns as a primary key, but for the synch we need an id
    self.id ||= "#{self.patient_id}_#{self.level_id}"
  end

  def calculate_status
    if self.level.completed? self.patient_id
      self.update!(status: :complete)
    elsif self.level.available? self.patient_id
      self.update!(status: :available)
    else
      self.update!(status: :unavailable)
    end
  end

  def cognitive_sessions
    CognitiveSession.for_patient(self.patient_id)
    .with_tree(self.level.exercise_trees.ids)
  end

  def completed_available_exercise_trees
    AvailableExerciseTree.for_patient(self.patient_id).complete
          .where(:exercise_tree_id => self.level.exercise_trees.ids)
  end

  def ongoing_available_exercise_trees
    # Find all available exercise trees not completed with at least one session
    AvailableExerciseTree.for_patient(self.patient_id).available
      .where(:exercise_tree_id => self.level.exercise_trees.ids)
      .where(
        :exercise_tree_id => LoadTreeEvent.where(:training_session_id => self.cognitive_sessions.ids).select(:tree_id)
      )
  end

  def correct_answers_percentage
    patient_sessions = self.cognitive_sessions
    
    answers = SessionEvent.patient_choices.where(:training_session_id => patient_sessions.select(:id))

    correct_answers = answers.where(
        page_id: PageLayout.where(correct: true).select(:page_id),
        card_id: PageLayout.where(correct: true).select(:card_id)
      )

    return correct_answers.count.to_f/answers.count.to_f
  end

  def average_selection_speed_ms
    tot = 0
    count = 0

    # Check all sessions of the patients
    # exclude sessions without patient choices
    self.cognitive_sessions.with_patient_choices.each do |session|
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
