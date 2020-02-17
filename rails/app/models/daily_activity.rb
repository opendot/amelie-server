class DailyActivity < ActiveModelSerializers::Model
  include TimeSpan
  # Resume of patient activity on a certain date

  attr_accessor :patient_id, :string
  attr_accessor :date, :datetime

  def initialize(patient_id, date)
    self.patient_id = patient_id
    self.date = date
  end

  def <=>(other)
    [patient_id, date] <=> [other.patient_id, other.date]
  end

  def date_string
    date_stringify(self.date)
  end

  # true if something happened in that day
  def has_something?
    return self.sessions.limit(1).count > 0 || self.has_badges?
  end

  def sessions
    TrainingSession.where(patient_id: self.patient_id, :start_time => in_date(self.date) )
  end

  def communication_sessions
    TrainingSession.where(type:"CommunicationSession", patient_id: self.patient_id, :start_time => in_date(self.date) )
  end

  def cognitive_sessions
    TrainingSession.where(type:"CognitiveSession", patient_id: self.patient_id, :start_time => in_date(self.date) )
  end

  def badges
    # search if there are badges in this date
    Badge.where(patient_id: self.patient_id, :date => in_date(self.date) )
  end

  def has_badges?
    self.badges.limit(1).count > 0
  end

  def to_simple_json
    {
      date: self.date_string,
      sessions_count: self.sessions.count,
      communication_count: self.communication_sessions.count,
      cognitive_count: self.cognitive_sessions.count,
      badges: self.has_badges?,
    }
  end

  # Return an array of DailyActivities
  def self.index( patient_id, fromDate = nil, toDate = nil )

    # Set default values
    if toDate.nil?
      toDate = DateTime.now.in_time_zone.at_beginning_of_day.to_datetime
    end
    if fromDate.nil?
      fromDate = toDate - 1.month
    end

    # Create an array of all dates
    days = TimeSpan.to_days(fromDate, toDate)

    # Create a DailyActivity for every day
    daily_activities = []
    days.each do |date|
      activity = DailyActivity.new( patient_id, date)
      if activity.has_something?
        daily_activities << activity.to_simple_json
      end
    end

    return daily_activities
  end

end