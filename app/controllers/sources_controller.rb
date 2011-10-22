class SourcesController < ApplicationController
  MAXIMUM_EVENTS_TO_DISPLAY_IN_FLASH = 5
  
  # Import sources
  def import
    @source = Source.find_or_create_from(params[:source])
    @events = nil # nil means events were never assigned, while [] means no events were found

    valid = @source.valid?
    if valid
      begin
        @events = @source.create_events!
      rescue SourceParser::NotFound => e
        @source.errors.add(:base, "No events found at remote site. Is the event identifier in the URL correct?")
      rescue SourceParser::HttpAuthenticationRequiredError => e
        @source.errors.add(:base, "Couldn't import events, remote site requires authentication.")
      rescue OpenURI::HTTPError => e
        @source.errors.add(:base, "Couldn't download events, remote site may be experiencing connectivity problems. ")
      rescue Errno::EHOSTUNREACH => e
        @source.errors.add(:base, "Couldn't connect to remote site.")
      rescue SocketError => e
        @source.errors.add(:base, "Couldn't find IP address for remote site. Is the URL correct?")
      rescue Exception => e
        @source.errors.add(:base, "Unknown error: #{e}")
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
            s << "<li>#{help.link_to(event.title, event_url(event))}</li>"
          end
        end
        s << "</ul>"
        flash[:success] = s

        format.html { redirect_to(events_path) }
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
  
  # GET /sources
  # GET /sources.xml
  def index
    @sources = Source.listing

    respond_to do |format|
      format.html { @sources = @sources.paginate(:page => params[:page], :per_page => params[:per_page]) }
      format.xml  { render :xml => @sources }
    end
  end

  # GET /sources/1
  # GET /sources/1.xml
  def show
    begin
      @source = Source.find(params[:id], :include => [:events, :venues])
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s if params[:id] != "import"
      return redirect_to(new_source_path)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @source }
    end
  end

  # GET /sources/new
  # GET /sources/new.xml
  def new
    @source = Source.new
    @source.url = params[:url] if params[:url].present?

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @source }
    end
  end

  # GET /sources/1/edit
  def edit
    @source = Source.find(params[:id])
  end

  # POST /sources
  # POST /sources.xml
  def create
    @source = Source.new(params[:source])

    respond_to do |format|
      if @source.save
        flash[:notice] = 'Source was successfully created.'
        format.html { redirect_to( source_path(@source) ) }
        format.xml  { render :xml => @source, :status => :created, :location => @source }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sources/1
  # PUT /sources/1.xml
  def update
    @source = Source.find(params[:id])

    respond_to do |format|
      if @source.update_attributes(params[:source])
        flash[:notice] = 'Source was successfully updated.'
        format.html { redirect_to( source_path(@source) ) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @source.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sources/1
  # DELETE /sources/1.xml
  def destroy
    @source = Source.find(params[:id])
    @source.destroy

    respond_to do |format|
      format.html { redirect_to(sources_url) }
      format.xml  { head :ok }
    end
  end
end
