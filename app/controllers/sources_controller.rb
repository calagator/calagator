class SourcesController < ApplicationController
  MAXIMUM_EVENTS_TO_DISPLAY_IN_FLASH = 5

  def index
    redirect_to new_source_path
  end

  def new
    @source = Source.new
    @page_title = "Import Events"
  end

  def update
    # Treat all #update actions as #create actions. Necessary because if the user submits the create form with an invalid Source, Rails does something which tries to direct this to the #update action, regardless of what paramters you specify to the #form_for helper.
    create
  end

  def create
    # TODO Import many sources at once

    @source = Source.new(params[:source])
    @events = nil
    @sources_to_events = {@source => @events}

    valid = @source.valid?
    if valid
      begin
        @sources_to_events = Source.create_sources_and_events_for!(@source.url)
        @source = @sources_to_events.keys.first
        @events = @sources_to_events.values.flatten
      rescue OpenURI::HTTPError
        @source.errors.add_to_base("that URL doesn't seem to be working")
      end
    end

    respond_to do |format|
      if valid && @events && @events.size > 0
        # TODO move this to a view, it currently causes a CGI::Session::CookieStore::CookieOverflow if the flash gets too big when too many events are imported at once
        s = "<p>Imported #{@events.size} entries:</p><ul>"
        @events.each_with_index do |event, i|
          if i >= MAXIMUM_EVENTS_TO_DISPLAY_IN_FLASH
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
        flash[:failure] = @events.nil? \
          ? "Unable to import: #{@source.errors.full_messages.to_sentence}" \
          : "Unable to find any upcoming events to import from this source"

        format.html { render :action => "new" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end
end
