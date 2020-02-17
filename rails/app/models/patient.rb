# This represents a patient
class Patient < ApplicationRecord
  after_create :create_relation_for_levels, :create_relation_for_boxes

  has_and_belongs_to_many :users, before_add: :limit_users
  has_one :tracker_calibration_parameter, dependent: :destroy
  has_many :custom_cards, dependent: :destroy
  has_many :custom_pages, dependent: :destroy
  has_many :training_sessions
  has_many :trees

  # Cogntive session
  has_many :available_levels, dependent: :destroy
  has_many :levels, through: :available_levels
  has_many :available_boxes, dependent: :destroy
  has_many :boxes, through: :available_boxes
  has_many :available_targets, dependent: :destroy
  has_many :targets, through: :available_targets
  has_many :available_exercise_trees, dependent: :destroy
  has_many :exercise_trees, through: :available_exercise_trees

  has_many :queued_synchronizables, dependent: :destroy

  validates :name, :surname, :birthdate, presence: true

  default_scope { order(:created_at) }

  # Create a relation between the newly created patient and all existing Level
  def create_relation_for_levels
    Level.all.each do |level|
      # Override updated_at to exclude the object from synchronization
      level.available_level_for(self.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  # Create a relation between the newly created patient and all existing Box
  def create_relation_for_boxes
    Box.all.each do |box|
      # Override updated_at to exclude the object from synchronization
      box.available_box_for(self.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  # Create a relation between the newly created patient and all existing Target
  def create_relation_for_targets
    Target.all.each do |target|
      # Override updated_at to exclude the object from synchronization
      target.available_target_for(self.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  # Create a relation between the newly created patient and all existing ExerciseTree
  def create_relation_for_exercise_trees
    ExerciseTree.all.each do |exercise_tree|
      # Override updated_at to exclude the object from synchronization
      exercise_tree.available_exercise_tree_for(self.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  def limit_users(user)
    if user.is_a? Parent
      if self.users.where(type: "Parent").limit(1).count > 0
        raise ActiveRecord::Rollback
      end
    end
  end

  def parent_id
    self.users.where(type: "Parent").ids.first
  end

  def parent
    Parent.where(id: self.parent_id).first
  end

  def tracker_calibration_parameter
    TrackerCalibrationParameter.where(patient_id: self.id).last
  end

  def queued_synchronizables?
    self.queued_synchronizables.limit(1).count > 0
  end

  def update_from_serialized serialized_patient_hash
    serialized_patient_hash.delete("id")
    self.update!(serialized_patient_hash)
  end

end
