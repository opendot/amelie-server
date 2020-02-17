class AvailableExerciseTree < ApplicationRecord
  include ParanoidSynchronizable
  # Used to track if a Patient has completed an ExerciseTree

  before_save :default_values
  
  belongs_to :patient, optional: true
  belongs_to :exercise_tree

  enum status: { available: 0, complete: 1, unavailable: 2, unpublished: 3 }

  validates :patient, uniqueness: { scope: :exercise_tree }

  delegate :name, :surname, :birthdate, to: :patient, prefix: true
  delegate :name, to: :exercise_tree, prefix: true

  scope :updated_at_least_once, -> {where.not(updated_at: DateTime.new(1969,1,1,0,0,0).in_time_zone)}
  
  def default_values
    # We should use the 2 columns as a primary key, but for the synch we need an id
    self.id ||= "#{self.patient_id}_#{self.exercise_tree_id}"
    self.conclusions_count ||= 0
    self.consecutive_conclusions_required ||= ExerciseTree::CONSECUTIVE_CONCLUSIONS_REQUIRED
  end

  def cognitive_sessions
    CognitiveSession.where(patient_id: self.patient_id).with_tree( self.exercise_tree_id)
  end

  def increment_count
    self.update!(conclusions_count: self.conclusions_count+1)
    update_available_box_conclusions_count
  end

  def decrement_count
    self.update!(conclusions_count: self.conclusions_count - 1)
    update_available_box_conclusions_count
  end

  def reset_count
    self.update!(conclusions_count: 0)
    update_available_box_conclusions_count
  end

  def update_available_box_conclusions_count
    available_box = self.exercise_tree.available_box_for(self.patient_id)
    if available_box.current_exercise_tree_id == self.exercise_tree_id
      available_box.update!(current_exercise_tree_conclusions_count: self.conclusions_count)
    end
  end

  def consecutive_conclusions_passed?
    self.conclusions_count >= self.consecutive_conclusions_required
  end

  # The total number of times the patient tried this exercise_tree
  def total_attempts_count
    if self.patient_id.nil?
      return -1
    else
      # In CognitiveSessions, we have only 1 LoadTreeEvent, the tree is the exercise
      return self.cognitive_sessions.count
    end
  end
end
