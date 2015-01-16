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
    parts = TimeParts.new(start_time, context_date, from_prefix: same_day?, no_meridian: same_meridian?)
    parts.to_s(format, "start")
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
    parts = TimeParts.new(end_time, context_date, time_only: same_day?)
    parts.to_s(format, "end")
  end

  def range?
    end_time.present? && start_time != end_time
  end

  def same_day?
    range? && start_time.to_date == end_time.to_date
  end

  def same_meridian?
    same_day? && start_time.strftime("%p") == end_time.strftime("%p")
  end

  # Get the parts for formatting this time, as a hash of 
  # strings: keys (roughly) match the equivalent methods on DateTime, but only
  # relevant keys will be filled in.
  # - if it's exactly noon or midnight, :hour will be eg "noon"
  #   (with no other time fields)
  #
  class TimeParts
    def initialize(time, context, time_only: false, no_meridian: false, from_prefix: false)
      @time = time
      @context = context
      @parts = get_parts
      remove_parts_implied_by_context
      remove_day_parts if time_only
      remove_suffix if no_meridian
      set_at_to_from if from_prefix
    end

    attr_reader :time, :context, :parts

    def to_s(format, which)
      Renderer.new(self, format, which).to_s
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
      parts.delete(:year) if context.year == time.year
      [:wday, :month, :day, :at, :from].each do |key|
        parts.delete(key)
      end if time.to_date == context
    end

    def remove_day_parts
      parts.keep_if { |key| [:hour, :min, :suffix].include?(key) }
    end

    def remove_suffix
      parts.delete(:suffix)
    end

    def set_at_to_from
      parts[:at] = "from" if parts.has_key?(:at)
    end

    class Renderer < Struct.new(:parts, :format, :which)
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

      def to_s
        if format == :hcal
          wrap_in_hcal(text, which)
        else
          text
        end
      end

      private

      def text
        parts.parts.reduce("") do |string, (key, value)|
          prefix = (PREFIXES[[@last_key, key]] || PREFIXES[key])
          suffix = SUFFIXES[key]
          @last_key = key
          "#{string}#{prefix}#{value}#{suffix}"
        end
      end

      def wrap_in_hcal(string, which)
        css_class = "dt#{which} dt-#{which}"
        formatted_time = parts.time.strftime('%Y-%m-%dT%H:%M:%S')
        %(<time class="#{css_class}" title="#{formatted_time}" datetime="#{formatted_time}">#{string}</time>)
      end
    end
  end
end
