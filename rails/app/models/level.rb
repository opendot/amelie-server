class Level < ApplicationRecord
  include ParanoidSynchronizable
  # Level of the cognitive enhancement boxes
  
  after_create :create_relation_for_patients
  after_destroy :deleted_callback

  has_many :boxes
  has_many :available_levels, dependent: :destroy
  has_many :patients, through: :available_levels

  validates :value, presence: true

  default_scope -> { order(:value, :name) }
  scope :base_params, -> {select(:id, :name, :value, :published, :updated_at)}
  scope :with_boxes, -> {includes(boxes: [:available_boxes])}
  scope :with_one_or_more_boxes, -> {includes(:boxes).where.not(boxes: { id: nil })}
  scope :with_boxes_count, -> {left_outer_joins(:boxes).group(:id).select("count(boxes.id) as boxes_count")}
  scope :published, -> {where(published: true)}
  scope :unpublished, -> {where(published: false)}
  
  # extra variables used to retrieve the list of levels for a Patient
  attr_accessor :available, :b
  
  # Create a relation between the newly created level and all existing Patients
  def create_relation_for_patients
    Patient.all.each do |patient|
      # Override updated_at to exclude the object from synchronization
      self.available_level_for(patient.id).update!(updated_at: DateTime.new(1969, 1, 1, 0, 0, 0).in_time_zone)
    end
  end

  def completed?(patient_id)
    available_level = self.available_level_for patient_id
    if available_level.nil?
      return false
    else
      return available_level.complete?
    end
  end

  def exercise_trees
    ExerciseTree.order_by_level_box_target.where(:levels => {id: self.id})
  end

  # Get the AvailableLevel for the given patient, create it if it doesn't exist
  def available_level_for patient_id
    if Patient.exists?(patient_id)
      return AvailableLevel.find_or_create_by!(level_id: self.id, patient_id: patient_id)
    else
      return nil
    end
  end

  # Check if the user can apply to this level
  def available?(patient_id)
    if self.deleted? then return false end

    if self.completed?(patient_id)
      return true
    end

    # Check if all the previous levels are complete
    return AvailableLevel.where(patient_id: patient_id).joins(:level).where("levels.value < ?", self.value).where(:levels => {published: true})
      .where(status: :complete).count == Level.published.where("value < ?", self.value).count

  end

  def conclude_for patient
    available_level = self.available_level_for(patient.id)
    raise "Can't conclude Level for not existing Patient" if available_level.nil?
    if available_level.update(status: :complete)
      Badge.create!(patient: patient, achievement: "level", level: self)
      # Update status of the next levels
      Level.published.where("value > ?", self.value).each do |l|
        l.available_level_for(patient.id).calculate_status
        l.boxes.published.includes(:available_boxes).each do |b|
          b.available_box_for(patient.id).update_status
        end
      end
    else
      raise ActiveRecord::Rollback, "Error conclude Level #{self.id}:#{self.name} for #{patient.id}"
    end
  end

  # A patient concluded a Box, update the status
  def concluded_box_for patient, box
    patient_available_boxes = patient.available_boxes.where(box_id: self.boxes.published)

    if patient_available_boxes.where(status: [:complete, :unavailable]).count == self.boxes.published.size
      # All boxes are completed, the Level is completed
      self.conclude_for patient
    end
  end

  def deleted_callback
    # Update status of the next levels
    Patient.all.each do |patient|
      Level.published.where("value > ?", self.value).each do |l|
        l.available_level_for(patient.id).calculate_status
        l.boxes.published.includes(:available_boxes).each do |b|
          b.available_box_for(patient.id).update_status
        end
      end
    end
  end

  def deleted_box box
    Patient.all.each do |patient|
      self.concluded_box_for patient, box
    end
  end

end
