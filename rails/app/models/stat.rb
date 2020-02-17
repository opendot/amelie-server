class Stat < ActiveModelSerializers::Model
  include TimeSpan
  # Statistics about the patient on a certain time span, usally the last N days

  attr_accessor :patient_id, :string
  attr_accessor :from_date, :datetime
  attr_accessor :to_date, :datetime

  def initialize(patient_id, from_date, to_date)
    self.patient_id = patient_id
    self.from_date = from_date
    self.to_date = to_date
  end

  def <=>(other)
    [patient_id, from_date, to_date] <=> [other.patient_id, other.from_date. other.to_date]
  end

  def stats_previous_span
    prev_to_date = self.from_date - 1.day
    days_span = (self.to_date - self.from_date).to_i
    prev_from_date = prev_to_date - days_span.days

    return Stat.new(self.patient_id, prev_from_date, prev_to_date)
  end

  def cognitive_sessions
    type = "CognitiveSession"
    prev_stat = self.stats_previous_span

    percentage = self.correct_answers_percentage
    count = self.sessions(type).count
    average_selection_speed_ms = average_selection_speed_ms(type)
    prev_average_selection_speed_ms = prev_stat.average_selection_speed_ms(type)

    # Calculate the datas for every single day
    percentage_correct_data, count_data, speed_data = self.cognitive_session_datas

    return {
      correct_answers: {
        percentage: percentage,
        difference: percentage - prev_stat.correct_answers_percentage,
        data: percentage_correct_data,
      },
      count: {
        count: count,
        average: self.average_daily_sessions(count_data),
        data: count_data,
      },
      average_selection_speed: {
        millis: average_selection_speed_ms,
        difference: prev_average_selection_speed_ms == 0 ? 1 : (self.average_selection_speed_ms(type).to_f/prev_average_selection_speed_ms.to_f - 1.0),
        data: speed_data,
      },
    }
  end

  def communication_sessions
    type = "CommunicationSession"

    count = self.sessions(type).count

    # Calculate the datas for every single day
    count_data = self.communication_session_datas

    return {
      count: {
        count: count,
        average: self.average_daily_sessions(count_data),
        data: count_data,
      },
    }
  end

  def correct_answers_percentage
    patient_sessions = self.sessions("CognitiveSession")
    
    answers = SessionEvent.patient_choices.where(:training_session_id => patient_sessions.select(:id))

    correct_answers = answers.where(
        page_id: PageLayout.where(correct: true).select(:page_id),
        card_id: PageLayout.where(correct: true).select(:card_id)
      )

    return correct_answers.count.to_f/answers.count.to_f
  end

  def sessions(type)
    TrainingSession.for_patient(self.patient_id)
    .where(type: type)
    .where(:start_time => self.from_date.at_beginning_of_day..self.to_date.end_of_day)
  end

  # Given the array containing sessions count for every day,
  # calculate the average
  def average_daily_sessions(count_data)
    tot = 0

    count_data.each do |data|
      tot += data[:count]
    end
    return tot.to_f/count_data.length
  end

  def average_selection_speed_ms(type)
    tot = 0
    count = 0

    # Check all sessions of the patients
    # exclude sessions without patient choices
    self.sessions(type).with_patient_choices.each do |session|
      average_selection = session.average_selection_speed_ms
      if average_selection > 0
        tot += average_selection
        count += 1
      end
    end

    if count == 0
      return 0
    end

    return tot/count
  end

  def cognitive_session_datas
    type = "CognitiveSession"
    days = TimeSpan.to_days(self.from_date, self.to_date)

    # Create a Stat for every day
    percentage_correct = []
    count = []
    average_selection_speed_ms = []
    days.each do |date|
      stat = Stat.new( patient_id, date.at_beginning_of_day, date.end_of_day)
      date_string = date_stringify(date)
      percentage_correct << {
        percentage: stat.correct_answers_percentage,
        date: date_string,
      }
      count << {
        count: stat.sessions(type).count,
        date: date_string,
      }
      average_selection_speed_ms << {
        millis: stat.average_selection_speed_ms(type),
        date: date_string,
      }
    end

    return percentage_correct, count, average_selection_speed_ms
  end

  def communication_session_datas
    days = TimeSpan.to_days(self.from_date, self.to_date)

    # Create a Stat for every day
    count = []
    days.each do |date|
      stat = Stat.new( patient_id, date.at_beginning_of_day, date.end_of_day)
      date_string = date_stringify(date)
      count << {
        count: stat.sessions("CognitiveSession").count,
        date: date_string,
      }
    end

    return count
  end

end