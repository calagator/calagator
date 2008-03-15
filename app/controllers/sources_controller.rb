require 'uri'

class SourcesController < ApplicationController
  def index
    redirect_to new_source_path
  end

  def new
  end

  def create
    @source = Source.new(params[:source])
    @events = nil
    events_added_counter = 0

    if @source.valid?
      @events = @source.to_events
      for event in @events
        next if event.title.blank? && event.description.blank? && event.url.blank?
        event.source = @source
        event.save!
        events_added_counter += 1
        if event.venue && event.venue.source.blank?
          event.venue.source = @source
          event.venue.save!
        end
      end
      @source.save! if events_added_counter > 0
    end

    respond_to do |format|
      if @source.valid? && events_added_counter > 0
        s = "<p>Imported #{@events.size} entries:</p><ul>"
        for event in @events
          s << "<li>#{help.link_to event.title, event_url(event)}</li>"
        end
        s << "</ul>"
        flash[:success] = s

        format.html { redirect_to events_path }
        format.xml  { render :xml => @source, :events => @events }
      else
        #flash[:failure] = "No items found to import. Please see [URL] for more information on what pages Calagator can read."
        flash[:failure] = "No items found to import: #{@source.errors.full_messages.to_sentence}"

        format.html { render :action => "new" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end
end
