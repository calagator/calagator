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
    flash[:success] = "Imported #{imported.size} entries"
    redirect_to events_path
  end
end
