# == Source::Parser::Hcal
#
# Reads hCalendar events.
class Source::Parser::Hcal < Source::Parser
  self.label = :hCalendar

  EVENT_TO_HCALENDAR_FIELD_MAP = {
    :title => :summary,
    :description => :description,
    :start_time => :dtstart,
    :end_time => :dtend,
    :url => :url,
    :venue => :location,
  }

  def to_events
    hcals.map do |hcal|
      event = Event.new
      event.source = opts[:source]
      EVENT_TO_HCALENDAR_FIELD_MAP.each do |field, mofo_field|
        next unless hcal.respond_to?(mofo_field)
        next unless value = decoded_field(hcal, mofo_field)
        event.send "#{field}=", value
      end
      event_or_duplicate(event)
    end.uniq do |event|
      [event.attributes, event.venue.try(:attributes)]
    end
  end

  private

  def decoded_field(hcal, mofo_field)
    return unless raw_field = hcal.send(mofo_field)
    decoded_field = case mofo_field
    when :dtstart
      HTMLEntities.new.decode(raw_field)
    when :location
      to_venue(opts.merge(:value => raw_field))
    else
      raw_field
    end
  end

  VENUE_TO_HCARD_FIELD_MAP = {
    :title => :fn,
    :telephone => :tel,
    :email => :email,
    :description => :note,
  }

  # Return a Venue.
  #
  # Options:
  # * :value -- hCard or string location
  def to_venue(opts)
    venue = Venue.new
    venue.source = opts[:source]
    case raw = opts[:value]
    when String
      venue.title = raw
    when HCard
      assign_fields(venue, raw)
      assign_geo(venue, raw) if raw.respond_to?(:geo)
      assign_address(venue, raw) if raw.respond_to?(:adr)
    end
    venue.geocode!
    venue_or_duplicate(venue)
  end

  def assign_fields(venue, raw)
    VENUE_TO_HCARD_FIELD_MAP.each do |field, mofo_field|
      venue[field] = raw.send(mofo_field).try(:strip_html) if raw.respond_to?(mofo_field)
    end
  end

  def assign_geo(venue, raw)
    %w(latitude longitude).each do |field|
      venue[field] = raw.geo.send(field) if raw.geo.respond_to?(field)
    end
  end

  def assign_address(venue, raw)
    attributes = %w(street_address locality region country_name postal_code).reduce({}) do |attributes, field|
      attributes[field] = raw.adr.send(field) if raw.adr.respond_to?(field)
      attributes
    end

    attributes["country"] = attributes.delete("country_name")
    attributes["postal_code"] = attributes["postal_code"].to_s if attributes["postal_code"]
    venue.attributes = attributes
  end

  def hcals
    content = self.class.read_url(opts[:url])
    something = hCalendar.find(:text => content)
    something.is_a?(hCalendar) ? [something] : something
  end
end
