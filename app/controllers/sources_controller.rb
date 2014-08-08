class SourcesController < ApplicationController
  MAXIMUM_EVENTS_TO_DISPLAY_IN_FLASH = 5
  
  # Import sources
  def import
    @importer = Source::Importer.new(params[:source])
    @source = @importer.source
    @events = @importer.events

    respond_to do |format|
      if @importer.events?
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
      format.html { @sources = @sources.paginate(page: params[:page], per_page: params[:per_page]) }
      format.xml  { render xml: @sources }
    end
  end

  # GET /sources/1
  # GET /sources/1.xml
  def show
    @source = Source.find(params[:id], include: [:events, :venues])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @source }
    end
  rescue ActiveRecord::RecordNotFound => error
    flash[:failure] = error.to_s if params[:id] != "import"
    redirect_to new_source_path
  end

  # GET /sources/new
  def new
    @source = Source.new
    @source.url = params[:url] if params[:url].present?
  end

  # GET /sources/1/edit
  def edit
    @source = Source.find(params[:id])
  end

  # POST /sources
  # POST /sources.xml
  def create
    @source = Source.new
    create_or_update
  end

  # PUT /sources/1
  # PUT /sources/1.xml
  def update
    @source = Source.find(params[:id])
    create_or_update
  end

  def create_or_update
    respond_to do |format|
      if @source.update_attributes(params[:source])
        format.html { redirect_to @source, notice: 'Source was successfully saved.' }
        format.xml  { render xml: @source, status: :created, location: @source }
      else
        format.html { render action: @source.new_record? ? "new" : "edit" }
        format.xml  { render xml: @source.errors, status: :unprocessable_entity }
      end
    end
  end
  private :create_or_update

  # DELETE /sources/1
  # DELETE /sources/1.xml
  def destroy
    @source = Source.find(params[:id])
    @source.destroy

    respond_to do |format|
      format.html { redirect_to sources_url }
      format.xml  { head :ok }
    end
  end
end
