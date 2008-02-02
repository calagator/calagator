class SourcesController < ApplicationController
  def index
  end

  def create
    imported = []
    params[:source][:url].strip!
    events = Source.new(params[:source]).to_events
    for event in events
      next if event.title.blank? && event.description.blank? && event.url.blank?
      event.save!
      imported << event
    end
    imported.size == 0 ? 
        flash[:success] = "No items found to import. Please see [URL] for more information on what pages Calagator can read." : 
        flash[:error] = "Imported #{imported.size} entries"
#    flash[:success] = "Imported #{imported.size} entries"
    redirect_to events_path
  end
end
