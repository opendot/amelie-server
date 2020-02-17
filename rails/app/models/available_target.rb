class AvailableTarget < ApplicationRecord
  include ParanoidSynchronizable
  # Used to track if a Patient has completed a Target

  before_save :default_values

  belongs_to :patient, optional: false
  belongs_to :target

  enum status: { available: 0, complete: 1, unavailable: 2 }

  validates :patient, uniqueness: { scope: :target }

  delegate :name, :surname, :birthdate, to: :patient, prefix: true
  delegate :name, to: :target, prefix: true

  scope :updated_at_least_once, -> {where.not(updated_at: DateTime.new(1969,1,1,0,0,0).in_time_zone)}
  
  def default_values
    # We should use the 2 columns as a primary key, but for the synch we need an id
    self.id ||= "#{self.patient_id}_#{self.target_id}"
  end
end
