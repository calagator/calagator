class SourcesController < ApplicationController
  def index
  end

  def create
    imported = []
    params[:source][:url].strip!
    source = Source.new(params[:source])
    events = source.to_events
    for event in events
      next if event.title.blank? && event.description.blank? && event.url.blank?
      event.source = source
      event.save!
      imported << event
    end
    imported.size == 0 ? 
        flash[:error] = "No items found to import. Please see [URL] for more information on what pages Calagator can read." : 
        flash[:success] = "Imported #{imported.size} entries"
    
    source.save!
    
    redirect_to events_path
  end
end
