class Broadcast < ActiveRecord::Base
  extend RadiaSource::TimeUtils
  
  belongs_to :program_schedule
  
  validates_presence_of :dtstart, :dtend, :program_schedule
  
  # Ensure that start datetime comes before end datetime
  validate :start_date_is_before_end_date
  
  # Ensure that there aren't any broadcast in this timeframe
  validate :does_not_conflict_with_others
  
  ### Class methods
  
  # Checks if it has a broadcast on a given day
  def self.has_broadcasts?(date)
    !find_by_date(date.year, date.month, date.day).blank?
  end
  
  # Find one broadcast on a certain date
  def self.find_by_date(year, month, day)
    find_all_by_date(year, month, day).first
  end
  
  # Finds all broadcasts within dtstart and dtend
  def self.find_in_range(startdt, enddt)
    find(:all, :conditions => ["(dtstart < ? AND dtend > ?) OR (dtstart >= ? AND dtend <= ?) OR (dtstart < ? AND dtend > ?)", 
                                startdt, startdt, startdt, enddt, enddt, startdt], :order => "dtstart ASC")
  end
  
  # Find all broadcasts on a certain date
  def self.find_all_by_date(year, month = nil, day = nil)
    if !year.blank?
      from, to = self.time_delta(year, month, day)
      find(:all, :conditions => ["dtstart BETWEEN ? AND ?", from, to], :order => "dtstart ASC")
    else
      find(:all, :order => "dtstart ASC")
    end
  end
  
  ### Instance methods
  
  def same_time?(other)
    (self.dtstart == other.dtstart) && (self.dtend == other.dtend)
  end
  
  def same_time?(dtstart, dtend)
    (self.dtstart == dtstart) && (self.dtend == dtend)
  end
  
  # Creates an array for params (to use the emission's date)
  def to_param
    param_array
  end
  
  def <=>(other)
    self.dtstart <=> other.dtstart
  end
  
  # Broadcast duration (in seconds) as Integer 
  def length
    (self.dtend.to_time - self.dtstart.to_time).to_i
  end

  # Convenience method to access start date/time year
  def year
    self.dtstart.year
  end

  # Convenience method to access start date/time month
  def month
    self.dtstart.month
  end

  # Convenience method to access start date/time day
  def day
    self.dtstart.day
  end

  # Convenience method to access start date/time hour
  def hour
    self.dtstart.hour
  end

  # Convenience method to access start date/time minute
  def minute
    self.dtstart.min
  end

  protected

  # Validation method.
  # Ensures that start date comes before end date
  def start_date_is_before_end_date
    return if self.dtstart.nil? or self.dtend.nil? # This should be caught by another validation
    errors.add(:dtend, "date/time can't be before start date/time") unless self.dtstart <= self.dtend
  end
  
  # Validation method.
  # Ensures that there aren't overlapping Broadcasts
  def does_not_conflict_with_others
    b = Broadcast.find_in_range(dtstart, dtend)
    if (b.size > 1) or (b.size == 1 and b.first != self) 
      errors.add_to_base("There are other broadcasts within the given timeframe (#{dtstart} - #{dtend})")
    end
  end

  def param_array
    @param_array ||=
    returning([year, sprintf('%.2d', month), sprintf('%.2d', day), id]) do |params|
      this = self
      k = class << params; self; end
      k.send(:define_method, :to_s) { params[-1] }
    end
  end
  
end