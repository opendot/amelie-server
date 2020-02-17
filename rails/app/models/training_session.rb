# A single training session
class TrainingSession < ApplicationRecord
  include Synchronizable
  
  belongs_to :user
  belongs_to :patient

  has_one :tracker_calibration_parameter, dependent: :destroy
  has_one :audio_file, dependent: :destroy
  has_many :session_events, dependent: :destroy
  has_many :tracker_raw_data, dependent: :destroy

  validates :start_time, :user_id, :patient_id, :tracker_calibration_parameter_id, presence: true
  validates :type, inclusion: { in: %w(CommunicationSession CognitiveSession LearningSession CalibrationSession), message: "%{value} #{I18n.t :error_training_session_type}" }

  delegate :name, :surname, to: :patient, prefix: true

  scope :with_tree,  ->  (tree_id){ where(:id => LoadTreeEvent.where(tree_id: tree_id).select("session_events.training_session_id AS id")) }
  scope :with_patient_choices, -> {where(:id => SessionEvent.patient_choices.select("training_session_id AS id"))}

  # The default order of these record is the creation date
  default_scope { order(:created_at) }

  def as_json(options={})
    super(options.merge({:methods => :type}))
  end

  def tree_id
    self.first_page_tree_id
  end

  def tree
    Tree.find_by(id: self.tree_id)
  end

  # Tree loaded with the first LoadTreeEvent
  def first_loaded_tree_id
    self.session_events.where(type: LoadTreeEvent).reorder(timestamp: :desc).first.tree_id
  end

  # Tree of the first page shown
  def first_page_tree_id

    if self.type == "CommunicationSession"
      pag = self.session_events.where(type: TransitionToPageEvent).reorder(timestamp: :desc).first.next_page_id
      return Page.find_by_id(pag).tree_id
    else
      return self.session_events.where(type: TransitionToPageEvent).reorder(timestamp: :desc).first.page.tree_id
    end
  end

  # Calculate session duration in seconds
  def calculate_duration
    end_event = self.session_events.where(type: TransitionToEndEvent).reorder(timestamp: :desc).last
    unless end_event.nil?
      self.update!(duration: end_event.timestamp - self.start_time )
    end
  end

  def average_selection_speed_ms
    tot = 0
    count = 0

    # Check the time between TransitionToPageEvent and PatientChoice events
    # I have to ignore feedback pages and patient_user_choices
    transition_to_page_event = nil
    self.session_events.where(type: "TransitionToPageEvent").each do |next_transition_to_page_event|
      unless transition_to_page_event.nil?
        patient_choice = self.session_events.patient_choices
          .where("timestamp > ?", transition_to_page_event.timestamp)
          .where("timestamp < ?", next_transition_to_page_event.timestamp)
          .reorder(timestamp: :asc).first
        
        unless patient_choice.nil?
          tot += patient_choice.timestamp_ms - transition_to_page_event.timestamp_ms
          count += 1
        end
      end
      transition_to_page_event = next_transition_to_page_event
    end

    # now check the time for the last page
    patient_choice = self.session_events.patient_choices
      .where("timestamp > ?", transition_to_page_event.timestamp)
      .reorder(timestamp: :asc).first
    
    unless patient_choice.nil?
      tot += patient_choice.timestamp_ms - transition_to_page_event.timestamp_ms
      count += 1
    end

    if count == 0
      return 0
    end
    
    return tot/count
  end

  # Create many object with a single query
  # This also allow to create a TrainingSession object in the local server even if the user is not in the db
  # WARNING the objects created skip validation, this must be used only for the Synchronization
  def self.create_from_array( hash_array )
    return if hash_array.empty?
    values = hash_array.map do |a|
      "('#{a[:id]}','#{DateTime.parse(a[:start_time]).utc.to_formatted_s(:db)}',#{a[:duration] || "NULL"},#{a[:screen_resolution_x] || "NULL"},#{a[:screen_resolution_y] || "NULL"},#{a[:tracker_type] ? "'#{a[:tracker_type]}'" : "NULL"},
      #{a[:user_id] ? "'#{a[:user_id]}'" : "NULL"},#{a[:patient_id] ? "'#{a[:patient_id]}'" : "NULL"},#{a[:audio_file_id] ? "'#{a[:audio_file_id]}'" : "NULL"},#{a[:tracker_calibration_parameter_id] ? "'#{a[:tracker_calibration_parameter_id]}'" : "NULL"},
      #{a[:type] ? "'#{a[:type]}'" : "NULL"},'#{DateTime.parse(a[:created_at]).utc.to_formatted_s(:db)}','#{(a[:updated_at].nil? ? DateTime.now : DateTime.parse(a[:updated_at])).utc.to_formatted_s(:db) }')"
    end
    values = values.join(",")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{self.table_name} #{self.keys} VALUES #{values}"
    )
  end

  protected

  def self.delete_preview_sessions
    TrainingSession.where("id LIKE 'preview%'").destroy_all
  end
end
