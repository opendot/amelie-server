class Badge < ApplicationRecord
  include Synchronizable
  # Achivement of a patient on the cognitive enjacement flow
  before_save :default_values, :set_fields_from_ids

  enum achievement: { level: 0, box: 1, target: 2, communication_count: 3  }

  belongs_to :patient, optional: false
  belongs_to :target, optional: true
  belongs_to :box, optional: true
  belongs_to :level, optional: true

  delegate :value, to: :level, prefix: true

  scope :cognitive_sessions, -> {where(:achievement => Badge.cognitive_session_achievements)}
  scope :communication_sessions, -> {where(:achievement => Badge.communication_session_achievements)}

  def default_values
    self.id ||= SecureRandom.uuid()
    self.date ||= DateTime.now.in_time_zone
  end

  # Set level and box base n target
  # this is used to set all values by setting only the target,
  # to simplify the creation of the object
  def set_fields_from_ids
    unless self.target.nil?
      self.target_name = self.target.name
      self.box = self.target.box
    end

    unless self.box.nil?
      self.box_name = self.box.name
      self.level = self.box.level
    end

    unless self.level.nil?
      self.level_name = self.level.name
    end
  end

  def self.communication_session_achievements
    %w(communication_count)
  end

  def self.cognitive_session_achievements
    %w(level box target)
  end

  def self.create_communication_count_badges?( communication_sessions_count)
    return false if communication_sessions_count <= 0
    valid_counts = [10, 25]
    interval = 50
    return valid_counts.include?(communication_sessions_count) || communication_sessions_count%interval == 0
  end

end
