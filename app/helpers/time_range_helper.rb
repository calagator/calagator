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

  def start_text
    text(start_time, start_parts, css_class: "dtstart dt-start")
  end

  def conjunction
    return unless range?
    if same_day?
      format == :text ? "-" : "&ndash;"
    else
      " through "
    end
  end

  def end_text
    return unless range?
    text(end_time, end_parts, css_class: "dtend dt-end")
  end

  def text(time, parts, css_class: nil)
    results = []
    results << %Q|<time class="#{css_class}" title="#{time.strftime('%Y-%m-%dT%H:%M:%S')}" datetime="#{time.strftime('%Y-%m-%dT%H:%M:%S')}">| if format == :hcal
    results << format_parts_by_list(parts)
    results << %Q|</time>| if format == :hcal
    results.join
  end

  def start_parts
    @start_parts ||= begin
      parts = TimeParts.new(start_time, context_date)
      if range? && same_day?
        parts.replace(:at, "from")
        parts.delete(:suffix) if same_meridian?
      end
      parts
    end
  end

  def end_parts
    TimeParts.new(end_time, context_date, time_only: same_day?)
  end

  def range?
    end_time.present? && start_time != end_time
  end

  def same_day?
    start_time.to_date == end_time.to_date
  end

  def same_meridian?
    start_time.strftime("%p") == end_time.strftime("%p")
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

  def format_parts_by_list(parts)
    # Given a hash of date parts, and a format_list of the keys
    # that should be emitted, produce a list of the pieces.
    #
    # Include any extra pieces implied by juxtaposition: eg,
    # if PREFIXES[:hour] is " ", include a " " piece just 
    # before the hour, unless nil immediately 
    # preceded :hour and we have a PREFIXES[[nil, :hour]], in
    # which case we'll emit that instead.
    results = []
    last_key = nil
    parts.each do |key, value|
      results << (PREFIXES[[last_key, key]] || PREFIXES[key])
      results << value
      results << SUFFIXES[key]
      last_key = key
    end
    results.join
  end

  # Get the parts for formatting this time, as a hash of 
  # strings: keys (roughly) match the equivalent methods on DateTime, but only
  # relevant keys will be filled in.
  # - if it's exactly noon or midnight, :hour will be eg "noon"
  #   (with no other time fields)
  #
  class TimeParts
    def initialize(time, context, time_only: false)
      @time = time
      @context = context
      @parts = get_parts
      remove_parts_implied_by_context
      remove_day_parts if time_only
    end

    attr_reader :time, :context

    delegate :[], :[]=, :each, :delete, to: :@parts

    def replace(key, value)
      @parts[key] = value if @parts.has_key?(key)
    end

    private

    def get_parts
      parts = {
        :wday => Date::DAYNAMES[time.wday],
        :month => Date::MONTHNAMES[time.month],
        :day => time.day.to_s,
        :year => time.year.to_s,
        :at => "at" }
      if time.min == 0
        return parts.merge(:hour => "midnight") if time.hour == 0
        return parts.merge(:hour => "noon") if time.hour == 12
      end
      if time.hour >= 12
        suffix = "pm"
        h = time.hour - (time.hour > 12 ? 12 : 0)
      else
        suffix = "am"
        h = time.hour == 0 ? 12 : time.hour
      end
      m = ":%02d" % time.min if time.min != 0
      parts.merge(:hour => h.to_s,
                    :min => m,
                    :suffix => suffix)
    end

    def remove_parts_implied_by_context
      return unless time && context
      @parts.delete(:year) if context.year == time.year
      [:wday, :month, :day, :at, :from].each do |key|
        @parts.delete(key)
      end if time.to_date == context
    end

    def remove_day_parts
      @parts.keep_if { |key| [:hour, :min, :suffix].include?(key) }
    end
  end
end
