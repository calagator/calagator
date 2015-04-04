# Export +events+ to an iCalendar file.
ActionController::Renderers.add(:ics) do |events, options|
  render text: Calagator::Event::IcalRenderer.render(events, url_helper: ->(event) { event_url(event) }),
    mime_type: "text/calendar"
end

