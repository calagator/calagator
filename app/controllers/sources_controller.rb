class SourcesController < ApplicationController
  def index
  end

  def create
    params[:source][:url].strip!
    source = Source.new(params[:source])
    events = source.to_events
    for event in events
      next if event.title.blank? && event.description.blank? && event.url.blank?
      event.source = source
      event.save!
    end
    source.save!

    if events.size == 0
      flash[:failure] = "No items found to import. Please see [URL] for more information on what pages Calagator can read."
    else
      s = "<p>Imported #{events.size} entries:</p><ul>"
      for event in events
        s << "<li>#{help.link_to event.title, event_url(event)}</li>"
      end
      s << "</ul>"
      flash[:success] = s
    end

    redirect_to events_path
  end
end
