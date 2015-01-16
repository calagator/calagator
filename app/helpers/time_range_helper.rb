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
    TimeRange.new(start_time, end_time, format, context).to_s.html_safe
  end  
end

class TimeRange < Struct.new(:start_time, :end_time, :format, :context_date)
  # A representation of a time or range of time that can format itself 
  # in a meaningful way. Examples:
  # "Thursday, April 3, 2008"
  # "Thursday, April 3, 2008 at 4pm"
  # "Thursday, April 3, 2008 from 4:30-6pm"
  # (context: in the list for today) "11:30am-2pm"
  # "Thursday-Friday, April 3-5, 2008"
  # (context: during 2008) "Thursday April 5, 2009 at 3:30pm through Friday, April 5 at 8:45pm, 2009"
  # (same, context: during 2009) "Thursday April 5 at 3:30pm through Friday, April 5 at 8:45pm"
  def to_s
    [start_text, conjunction, end_text].compact.join
  end

  private

  def start_details
    @start_details ||= begin
      details = time_details(start_time)
      if range? && same_day?
        details[:at] = "from"
        details.delete(:suffix) if same_meridiem?
      end
      remove_stuff_implied_by_context start_time, details
      details
    end
  end

  def end_details
    @end_details ||= begin
      if range?
        details = time_details(end_time)
        details = details.keep_if { |key| [:hour, :min, :suffix].include?(key) } if same_day?
        remove_stuff_implied_by_context end_time, details
        details
      else
        {}
      end
    end
  end

  def range?
    end_time.present? && start_time != end_time
  end

  def same_day?
    start_time.to_date == end_time.to_date
  end

  def same_meridiem?
    start_time.strftime("%p") == end_time.strftime("%p")
  end

  def text_format?
    format == :text
  end

  def remove_stuff_implied_by_context time, details
    return unless time && context_date
    details.delete(:year) if context_date.year == time.year
    [:wday, :month, :day, :at, :from].each do |key|
      details.delete(key)
    end if time.to_date == context_date
  end

  def start_text
    component(start_time, start_details, css_class: "dtstart dt-start")
  end

  def conjunction
    return unless range?
    if same_day?
      text_format? ? "-" : "&ndash;"
    else
      " through "
    end
  end

  def end_text
    return unless range?
    component(end_time, end_details, css_class: "dtend dt-end")
  end

  def component(time, details, css_class: nil)
    results = []
    results << %Q|<time class="#{css_class}" title="#{time.strftime('%Y-%m-%dT%H:%M:%S')}" datetime="#{time.strftime('%Y-%m-%dT%H:%M:%S')}">| if format == :hcal
    results << format_details_by_list(details)
    results << %Q|</time>| if format == :hcal
    results.join
  end

  PREFIXES = {
    :hour => " ",
    [nil, :hour] => "",
    :year => ", ",
    :end_hour => " ",
    :end_year => ", ",
    :at => " ",
  }
  SUFFIXES = {
    :month => " ",
    :wday => ", ",
  }

  def format_details_by_list(details)
    # Given a hash of date details, and a format_list of the keys
    # that should be emitted, produce a list of the pieces.
    #
    # Include any extra pieces implied by juxtaposition: eg,
    # if PREFIXES[:hour] is " ", include a " " piece just 
    # before the hour, unless nil immediately 
    # preceded :hour and we have a PREFIXES[[nil, :hour]], in
    # which case we'll emit that instead.
    results = []
    last_key = nil
    details.each do |key, value|
      results << (PREFIXES[[last_key, key]] || PREFIXES[key])
      results << value
      results << SUFFIXES[key]
      last_key = key
    end
    results.join
  end

  def time_details(t)
    # Get the parts for formatting this time, as a hash of 
    # strings: keys (roughly) match the equivalent methods on DateTime, but only
    # relevant keys will be filled in.
    # - if it's exactly noon or midnight, :hour will be eg "noon"
    #   (with no other time fields)
    #
    details = {
      :wday => Date::DAYNAMES[t.wday],
      :month => Date::MONTHNAMES[t.month],
      :day => t.day.to_s,
      :year => t.year.to_s,
      :at => "at" }
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
