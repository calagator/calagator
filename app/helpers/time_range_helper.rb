module TimeRangeHelper
  # Initialize with a single DateTime, a pair of DateTimes,
  # or an object that responds_to start_time and end_time, and two options
  # By default (unless :format => :text) include <abbr> tags for hCalendar,
  # if a :context date is provided, omit unnecessary date parts.
  def normalize_time(start_time, end_time=nil, format: :hcal, context: nil)
    if end_time.nil? and start_time.respond_to?(:start_time)
      end_time = start_time.end_time
      start_time = start_time.start_time
    end
    TimeRange.new(start_time, end_time, format: format, context: context).to_s.html_safe
  end  
end

class TimeRange
  # A representation of a time or range of time that can format itself 
  # in a meaningful way. Examples:
  # "Thursday, April 3, 2008"
  # "Thursday, April 3, 2008 at 4pm"
  # "Thursday, April 3, 2008 from 4:30-6pm"
  # (context: in the list for today) "11:30am-2pm"
  # "Thursday-Friday, April 3-5, 2008"
  # (context: during 2008) "Thursday April 5, 2009 at 3:30pm through Friday, April 5 at 8:45pm, 2009"
  # (same, context: during 2009) "Thursday April 5 at 3:30pm through Friday, April 5 at 8:45pm"
  def initialize(start_time, end_time=nil, format: nil, context: nil)
    @start_time = start_time
    @end_time = end_time
    @format = format
    @context_date = context
  end

  attr_reader :start_time, :end_time, :format, :context_date

  def to_s
    figure_out_the_general_format
    remove_stuff_implied_by_context
    combine_the_pieces
  end

  private

  def figure_out_the_general_format
    # Assume one date only, equal start/end
    @start_format_list = [nil, :wday, :month, :day, :year, :at, :hour, :min, :suffix, nil]
    
    @start_details = time_details(start_time)
    if range?
      @end_details = time_details(end_time)
      if start_time.to_date == end_time.to_date
        @start_format_list[@start_format_list.index(:at)] = :from
        @conjunction = format == :text ? "-" : "&ndash;"
        if @start_details[:suffix] == @end_details[:suffix]
          # same day & am/pm
          # Tuesday, April 1, 2008 from 9-11am
          @start_format_list.delete(:suffix)
          @end_format_list = [nil, :hour, :min, :suffix, nil]
        else
          # same day, different am/pm
          # Tuesday, April 1, 2008 from 9am-1:30pm
          @end_format_list = [nil, :hour, :min, :suffix, nil]
        end
      else
        # different days: 
        # Tuesday, April 1, 2008 at 9am through Wednesday, April 1, 2009 at 1:30pm
        @end_format_list = @start_format_list.clone
        @conjunction = " through "
      end
    end
  end

  def range?
    end_time.present? && start_time != end_time
  end

  def remove_stuff_implied_by_context
    if context_date
      # Do it to both start & end lists
      [[start_time, @start_format_list], [end_time, @end_format_list]].each do |t, list|
        if t and list
          list.delete(:year) if context_date.year == t.year # same year
          [:wday, :month, :day, :at, :from].each do |k|
            list.delete(k)
          end if context_date == t.to_date
        end
      end
    end
  end

  def combine_the_pieces
    results = []
    results << %Q|<time class="dtstart dt-start" title="#{start_time.strftime('%Y-%m-%dT%H:%M:%S')}" datetime="#{start_time.strftime('%Y-%m-%dT%H:%M:%S')}">| if format == :hcal
    results << format_details_by_list(@start_details, @start_format_list)
    results << %Q|</time>| if format == :hcal
    if range?
      results << @conjunction
      results << %Q|<time class="dtend dt-end" title="#{end_time.strftime('%Y-%m-%dT%H:%M:%S')}" datetime="#{end_time.strftime('%Y-%m-%dT%H:%M:%S')}">| if format == :hcal
      results << format_details_by_list(@end_details, @end_format_list)
      results << %Q|</time>| if format == :hcal
    end
    results.join('').html_safe
  end

  PREFIXES = {
    :hour => " ",
    [nil, :hour] => "",
    :year => ", ",
    :end_hour => " ",
    :end_year => ", ",
  }
  SUFFIXES = {
    :month => " ",
    :wday => ", ",
  }
  STRINGS = {
    :from => " from",
    :at => " at",
  }

  def format_details_by_list(details, format_list)
    # Given a hash of date details, and a format_list of the keys
    # that should be emitted, produce a list of the pieces.
    #
    # Include any extra pieces implied by juxtaposition: eg,
    # if PREFIXES[:hour] is " ", include a " " piece just 
    # before the hour, unless nil immediately 
    # preceded :hour and we have a PREFIXES[[nil, :hour]], in
    # which case we'll emit that instead.
    results = []
    format_list.each_cons(3) do |before, part, after|
      results << (PREFIXES[[before, part]] || PREFIXES[part])
      results << (details[part] || STRINGS[part])
      results << (SUFFIXES[[part, after]] || SUFFIXES[part])
    end
    results
  end

  def date_details(d)
    # Get the parts for formatting a date, as a hash of 
    # strings: keys (roughly) match the equivalent methods on Date, but only
    # relevant keys will be filled in.
    { :wday => Date::DAYNAMES[d.wday],
      :month => Date::MONTHNAMES[d.month],
      :day => d.day.to_s,
      :year => d.year.to_s }
  end

  def time_details(t)
    # Get the parts for formatting this time, as a hash of 
    # strings: keys (roughly) match the equivalent methods on DateTime, but only
    # relevant keys will be filled in.
    # - if it's exactly noon or midnight, :hour will be eg "noon"
    #   (with no other time fields)
    details = date_details(t)
    if t.min == 0
      return details.merge(:hour => "midnight") if t.hour == 0
      return details.merge(:hour => "noon") if t.hour == 12
    end
    if t.hour >= 12
      suffix = "pm"
      h = t.hour - (t.hour > 12 ? 12 : 0)
    else
      suffix = "am"
      h = t.hour == 0 ? 12 : t.hour
    end
    m = ":%02d" % t.min if t.min != 0
    details.merge(:hour => h.to_s,
                  :min => m,
                  :suffix => suffix)
  end
end
