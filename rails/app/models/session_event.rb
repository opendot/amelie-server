class SessionEvent < ApplicationRecord
  include Synchronizable

  # Most of session events should not have a tracker calibration parameter.
  before_save :ensure_tracker_calibration_parameter_id_is_nil
  # Most of session events should not reference a card.
  before_save :ensure_card_id_is_nil
  # Most of session events should not reference a next page.
  before_save :ensure_next_page_id_is_nil
  # Ensure that the session event has an id.
  before_save :set_an_id
  # Ensure that the session event has a timestamp.
  before_create :set_the_timestamp

  # The training session the current event belongs to.
  belongs_to :training_session
  # The page that generated the current event.
  belongs_to :page, optional: true
  belongs_to :card, optional: true
  belongs_to :tree, optional: true
  
  validates :type, inclusion: { in: %w(LoadTreeEvent JumpToPageEvent BackEvent SoundAlertEvent VisualAlertEvent EyetrackerLockEvent EyetrackerUnlockEvent ShuffleEvent TrackerCalibrationParameterChangeEvent PatientEyeChoiceEvent PatientTouchChoiceEvent PatientUserChoiceEvent TransitionToPageEvent TransitionToPresentationPageEvent TransitionToFeedbackPageEvent TransitionToEndEvent TransitionToIdleEvent PlayVideoEvent PauseVideoEvent EndVideoEvent EndExtraPageEvent TimeoutEvent), message: "%{value} #{I18n.t :error_event_type}" }

  # Default ordering.
  default_scope { order(:timestamp, :created_at) }
  scope :patient_choices, -> {where(type: ["PatientEyeChoiceEvent", "PatientTouchChoiceEvent"])}

  def as_json(options={})
    super(options.merge({:methods => :type}))
  end

  def timestamp_ms
    self.timestamp.to_datetime.strftime('%Q').to_i
  end

  protected

  def ensure_tracker_calibration_parameter_id_is_nil
    self.tracker_calibration_parameter_id = nil
  end

  def ensure_card_id_is_nil
    self.card_id = nil
  end

  def ensure_next_page_id_is_nil
    self.next_page_id = nil
  end

  def set_an_id
    if self.id.blank?
      self.id = SecureRandom.uuid()
    end
  end

  def set_the_timestamp
    if self.timestamp.blank?
      self.timestamp = DateTime.current
    end
  end
  
  # Create many object with a single query
  # WARNING the objects created skip validation, this must be used only for the Synchronization
  def self.create_from_array( hash_array )
    return if hash_array.empty?
    values = hash_array.map do |a|
      "('#{a[:id]}','#{DateTime.parse(a[:timestamp]).utc.to_formatted_s(:db)}','#{a[:training_session_id]}',#{a[:page_id] ? "'#{a[:page_id]}'" : "NULL"},#{a[:tracker_calibration_parameter_id] ? "'#{a[:tracker_calibration_parameter_id]}'" : "NULL"},#{a[:card_id] ? "'#{a[:card_id]}'" : "NULL"},#{a[:next_page_id] ? "'#{a[:next_page_id]}'" : "NULL"},'#{a[:type]}','#{DateTime.parse(a[:created_at]).utc.to_formatted_s(:db)}','#{(a[:updated_at].nil? ? DateTime.now : DateTime.parse(a[:updated_at])).utc.to_formatted_s(:db)}',#{a[:tree_id] ? "'#{a[:tree_id]}'" : "NULL"})"
    end
    values = values.join(",")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{self.table_name} #{self.keys} VALUES #{values}"
    )
  end

end
