# frozen_string_literal: true

# Export +events+ to an iCalendar file.
ActionController::Renderers.add(:ics) do |events, _options|
  render plain: Calagator::Event::IcalRenderer.render(events, url_helper: ->(event) { event_url(event) }),
         content_type: 'text/calendar'
end
