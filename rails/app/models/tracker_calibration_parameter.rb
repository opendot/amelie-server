# Parameters of the tracker
class TrackerCalibrationParameter < ApplicationRecord
  include Synchronizable
  
  before_create :check_id_presence

  enum setting: { manual: 1, automatic: 2 }

  validates :fixing_radius, :fixing_time_ms, presence: true
  validates :type, inclusion: { in: %w(TobiiCalibrationParameter), message: "%{value} #{I18n.t :error_calibration_parameter_type}" }

  belongs_to :patient, optional: true # Could also be relative to a session only
  belongs_to :training_session, optional: true # Could also be relative to the patient only
  belongs_to :tracker_calibration_parameter_change_event, optional: true # Could be realtive to a patient or a training session

  default_scope { order(:created_at) }

  def as_json(options={})
    super(options.merge({:methods => :type}))
  end

  # Returns a deep clone of the current object
  def get_a_clone
    new_params = self.dup
    new_params.id = SecureRandom.uuid()
    unless new_params.save
      raise ActiveRecord::Rollback, "Can't save the cloned tracker_calibration_parameter: #{new_params.errors.full_messages}"
    end
    return new_params
  end

  protected

  def check_id_presence
    if self.id.nil?
      self.id = SecureRandom.uuid()
    end
  end
end
