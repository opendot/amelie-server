# Basic info gathered by TrainingSession, the positionrecorded by the eyetracker at the given time
class TrackerRawDatum < ApplicationRecord
  include Synchronizable

  validates :x_position, :y_position, presence: true
  belongs_to :training_session

  before_create :insert_id
  before_create :check_timestamp

  # Default ordering.
  default_scope { order(:timestamp, :created_at) }

  private

  def insert_id
    if self[:id].blank?
      self[:id] = SecureRandom.uuid()
    end
  end

  def check_timestamp
    if self[:timestamp].blank?
      self[:timestamp] = DateTime.current
    end
  end

  # Create many object with a single query
  # WARNING the objects created skip validation, this must be used only for the Synchronization
  def self.create_from_array( hash_array )
    return if hash_array.empty?
    values = hash_array.map do |a|
      "('#{a[:id]}','#{DateTime.parse(a[:timestamp]).utc.strftime('%Y-%m-%d %H:%M:%S.%L')}',#{a[:x_position]},#{a[:y_position]},'#{a[:training_session_id]}','#{DateTime.parse(a[:created_at]).utc.to_formatted_s(:db)}','#{(a[:updated_at].nil? ? DateTime.now : DateTime.parse(a[:updated_at])).utc.to_formatted_s(:db)}')"
    end
    values = values.join(",")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO #{self.table_name} #{self.keys} VALUES #{values}"
    )
  end

end
