module TimeSpan
  # Allow to handle a time span between 2 given dates from_date to_date

  def date_stringify(date)
    date.strftime("%d-%m-%Y")
  end

  def from_date_string
    self.date_stringify(self.from_date)
  end

  def to_date_string
    self.date_stringify(self.to_date)
  end

  # Used to search
  # where( :created_at => in_date(self.date) )
  def in_date( date )
    date.at_beginning_of_day..date.end_of_day
  end

  # Return an array of dates between the given dates
  # the given dates are included
  def self.to_days(from, to)
    # List of datetimes, convert into string and remove duplicates
    days = (from..to).map{ |date| date.in_time_zone.at_beginning_of_day.to_datetime }.uniq
    if days.last != to
      days << to.dup
    end
    return days
  end
end