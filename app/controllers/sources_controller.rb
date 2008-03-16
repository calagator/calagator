require 'uri'

class SourcesController < ApplicationController
  def index
    redirect_to new_source_path
  end

  def new
    @source = Source.new
  end

  def create
    @source = Source.find(:first, :conditions => params[:source]) || Source.new(params[:source])
    @events = nil
    events_added_counter = 0

    valid = @source.valid?
    if valid
      begin
        @events = @source.to_events
      rescue OpenURI::HTTPError
        @source.errors.add_to_base("that URL doesn't seem to be working")
      else
        for event in @events
          next if event.title.blank? && event.description.blank? && event.url.blank?
          event.save!
          events_added_counter += 1
          event.venue.save! if event.venue
        end
        @source.save! if events_added_counter > 0
      end
    end

    respond_to do |format|
      if valid && events_added_counter > 0
        # TODO move this to a view, it currently causes a CGI::Session::CookieStore::CookieOverflow if the flash gets too big when too many events are imported at once
        s = "<p>Imported #{@events.size} entries:</p><ul>"
        @events.each_with_index do |event, i|
          if i >= 5
            s << "<li>And #{@events.size - i} other events.</li>"
            break 
          else
            s << "<li>#{help.link_to event.title, event_url(event)}</li>"
          end
        end
        s << "</ul>"
        flash[:success] = s

        format.html { redirect_to events_path }
        format.xml  { render :xml => @source, :events => @events }
      else
        flash[:failure] = (@events.nil? ? "Unable to import: " : "No items found to import: ") +
                          @source.errors.full_messages.to_sentence

        format.html { render :action => "new" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end
end
