class Box < ApplicationRecord
  include ParanoidSynchronizable
  # Main argument of the cognitive enhancement flow
  # It's a collection of targets, executed one after another based
  # on the position value defined in box_layouts

  after_create :create_relation_for_patients
  after_destroy :deleted_callback

  belongs_to :level
  has_many :box_layouts, dependent: :destroy
  has_many :targets, -> { order 'box_layouts.position ASC' }, through: :box_layouts
  has_many :available_boxes, dependent: :destroy
  has_many :patients, through: :available_boxes

  validates :name, presence: true

  delegate :value, :name, to: :level, prefix: true

  scope :base_params, -> {select(:id, :name, :level_id, :updated_at)}
  scope :published, -> {where(published: true)}
  scope :unpublished, -> {where(published: false)}
  scope :with_targets_count, -> {left_outer_joins(:targets).group(:id).select("count(targets.id) as targets_count")}

  attr_accessor :available_box

  def add_target( target, position = 0)
    BoxLayout.create!(box: self, target: target, position: position)
    update_available_boxes
  end

  # Create a relation between the newly created box and all existing Patients
  def create_relation_for_patients
    Patient.all.each do |patient|
      # Override updated_at to exclude the object from synchronization
      self.available_box_for(patient.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  # Update common values of all available_boxes
  def update_available_boxes
    targets_count = self.targets.published.count
    self.available_boxes.each do |ab|

      current_target = Target.find_by(id: ab.current_target_id)
      if current_target.nil?
        current_target = self.first_target
      end
      
      ab.update!(
        targets_count: targets_count,
      )

      unless current_target.nil?
        current_exercise_tree = if ab.current_exercise_tree_id.nil? then current_target.first_exercise_tree else current_target.current_exercise_tree(ab.patient) end
        ab.set_current(current_target, current_exercise_tree)
      end
    end
  end

  # Get the AvailableBox for the given patient, create it if it doesn't exist
  def available_box_for patient_id
    if Patient.exists?(patient_id)
      return AvailableBox.find_or_create_by!(box_id: self.id, patient_id: patient_id)
    else
      return nil
    end
  end

  # Check if the user can apply to this box
  def available?(patient_id)
    return self.level.available? patient_id
  end

  def first_target
    self.targets.published.first
  end

  # get the target that the given patient have to do, the first uncompleted target
  def current_target patient
    self.targets.published.where.not(:id => patient.available_targets.complete.select("target_id as id")).first
  end

  # Percentage of targets completed by the patient
  def calculate_progress(patient)
    if patient.nil? then return 0 end
    targets_count = self.targets.published.size
    if targets_count == 0 then return 0 end
    return Float(self.targets.published.where(:id => patient.available_targets.complete.select("target_id as id")).count)/targets_count
  end

  def conclude_for patient
    available_box = self.available_box_for(patient.id)
    return if available_box.nil?
    available_box.conclude
    Badge.create!(patient: patient, achievement: "box", box: self)
    self.level.concluded_box_for patient, self
  end

  # A patient concluded a Target, update the status
  def concluded_target_for patient, target
    patient_available_targets = patient.available_targets.where(target_id: self.targets.published)

    if patient_available_targets.where(status: [:complete, :unavailable]).count == self.targets.published.size
      # All targets are completed, the Box is completed
      self.conclude_for patient
    else
      # Set the next target
      next_target = self.current_target(patient)
      available_box = self.available_box_for(patient.id)
      available_box.set_current( next_target, next_target.first_exercise_tree )
    end
  end

  # A patient concluded an ExerciseTree, update the status
  def concluded_exercise_tree_for patient, target
    available_box = self.available_box_for(patient.id)
    # Set the new current_exercise_tree
    available_box.set_current( target, target.current_exercise_tree(patient) )
  end

  def deleted_callback
    self.level.deleted_box self
  end

  def deleted_target target
    Patient.all.each do |patient|
      self.concluded_target_for patient, target
    end
  end

  # Change the order of the targets
  def reorder_targets(order_array)
    # Get all box_layouts, the objects who holds the position field
    box_layouts = self.box_layouts.where(:target_id => order_array)

    if order_array.length != box_layouts.count
      return false
    end

    box_layouts.each do |box_layout|
      box_layout.update( position: order_array.index(box_layout.target_id)+1)
    end

    return true
  end

end
