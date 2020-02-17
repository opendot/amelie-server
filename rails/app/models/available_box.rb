class AvailableBox < ApplicationRecord
  include ParanoidSynchronizable
  # Used to track if a Patient has completed a Box

  before_save :default_values
  after_create :update_status, :initialize_current_target

  belongs_to :patient, optional: false
  belongs_to :box

  enum status: { available: 0, complete: 1, unavailable: 2 }

  validates :patient, uniqueness: { scope: :box }
  validates :progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

  delegate :name, :surname, :birthdate, to: :patient, prefix: true
  delegate :name, to: :box, prefix: true

  scope :with_box_and_level, -> {joins(box: [:level])}
  scope :select_info, -> {select(:id, :box_id, :status, :progress, :current_target_id, :current_target_name, :current_target_position, :targets_count, :current_exercise_tree_id, :current_exercise_tree_name, :current_exercise_tree_conclusions_count, :current_exercise_tree_consecutive_conclusions_required, :target_exercise_tree_position, :target_exercise_trees_count, :last_completed_exercise_tree_at)}
  scope :select_box_and_level_info, -> {select("boxes.name as box_name", "boxes.published as box_published", "levels.id as level_id", "levels.name as level_name", "levels.value as level_value", "levels.published as level_published")
    .order("level_value ASC, box_name ASC")}
  scope :add_box_and_level, -> {includes(:box).with_box_and_level.select_box_and_level_info.where(:levels => {published: true}, :boxes => {published: true})}
  scope :updated_at_least_once, -> {where.not(updated_at: DateTime.new(1969,1,1,0,0,0).in_time_zone)}

  def default_values
    # We should use the 2 columns as a primary key, but for the synch we need an id
    self.id ||= "#{self.patient_id}_#{self.box_id}"
  end

  # Set as current target the first target of the box
  def initialize_current_target
    first_target = self.box.first_target
    
    unless first_target.nil?
      first_exercise_tree = first_target.first_exercise_tree
      self.set_current(first_target, first_exercise_tree)
      self.update!(
        targets_count: self.box.box_layouts.count,
      )
    end
  end

  # Update properties with a new target and exercise_tree
  def set_current( target, exercise_tree)
    if target.nil?
      return
    end

    box_layout = BoxLayout.where(box_id: self.box.id, target_id: target.id).first
    target_layout = if exercise_tree.nil? then nil else TargetLayout.where(target_id: target.id, exercise_tree_id: exercise_tree.id).first end
    available_exercise_tree = if exercise_tree.nil? then nil else exercise_tree.available_exercise_tree_for(self.patient.id) end

    progress = self.box.calculate_progress(self.patient)
    self.update!(
      status: if progress == 1 then :complete elsif self.box.available?(self.patient.id) then :available else :unavailable end,
      progress: progress,
      current_target_id: target.id,
      current_target_name: target.name,
      current_target_position: box_layout.position,
      current_exercise_tree_id: if exercise_tree.nil? then nil else exercise_tree.id end,
      current_exercise_tree_name: if exercise_tree.nil? then nil else exercise_tree.name end,
      current_exercise_tree_conclusions_count: if available_exercise_tree.nil? then nil else available_exercise_tree.conclusions_count end,
      current_exercise_tree_consecutive_conclusions_required: if available_exercise_tree.nil? then nil else available_exercise_tree.consecutive_conclusions_required end,
      target_exercise_tree_position: if target_layout.nil? then 0 else target_layout.position end,
      target_exercise_trees_count: target.target_layouts.count
    )
  end

  def update_status
    progress = self.box.calculate_progress(self.patient)
    self.update!(status: if progress == 1 then :complete elsif self.box.available?(self.patient.id) then :available else :unavailable end,)
  end

  def conclude
    self.update!(
      status: :complete,
      progress: 1,
      current_target_position: self.targets_count,
      target_exercise_tree_position: self.target_exercise_trees_count,
    )
  end
end
