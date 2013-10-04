class VenuesController < ApplicationController
  include SquashManyDuplicatesMixin # Provides squash_many_duplicates

  # GET /venues
  # GET /venues.xml
  def index
    scoped_venues = Venue.non_duplicates

    # Pick a subset of venues (we want in_business by default)
    if params[:include_closed]
      scoped_venues = scoped_venues
    elsif params[:closed]
      scoped_venues = scoped_venues.out_of_business
    else
      scoped_venues = scoped_venues.in_business
    end

    # Support old ajax autocomplete parameter name
    params[:term] = params[:val] if params[:val]

    @tag = nil
    if params[:tag].present? # searching by tag
      @tag = params[:tag]
      @venues = scoped_venues.tagged_with(@tag)
    elsif params.has_key?(:query) || params.has_key?(:term) || params[:all] == '1' # searching by query
      scoped_venues = scoped_venues.with_public_wifi if params[:wifi]

      if params[:term].present? # for the ajax autocomplete widget
        conditions = ["title LIKE :query", {:query => "%#{params[:term]}%"}]
        @venues = scoped_venues.find(:all, :order => 'lower(title)', :conditions => conditions)
      elsif params[:query].present?
        @venues = Venue.search(params[:query], :include_closed => params[:include_closed], :wifi => params[:wifi])
      else
        @venues = scoped_venues.all
      end
    else # default view
      @most_active_venues = scoped_venues.limit(10).order('events_count DESC')
      @newest_venues = scoped_venues.limit(10).order('created_at DESC')
    end

    @page_title = "Venues"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml  => @venues || scoped_venues }
      format.json { render :json => @venues || scoped_venues, :callback => params[:callback] }
      format.js   { render :json => @venues || scoped_venues, :callback => params[:callback] }
      format.kml  { @venues ||= scoped_venues; render } # index.kml.erb
    end
  end

  # GET /venues/map
  def map
    @venues = Venue.non_duplicates.in_business
  end

  # GET /venues/1
  # GET /venues/1.xml
  def show
    begin
      @venue = Venue.find(params[:id], :include => :source)
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to(venues_path)
    end

    return redirect_to(venue_url(@venue.duplicate_of)) if @venue.duplicate?

    @page_title = @venue.title

    respond_to do |format|
      format.html {
        @future_events = @venue.events.order("start_time ASC").future.non_duplicates.includes(:venue)
        @past_events = @venue.events.order("start_time DESC").past.non_duplicates.includes(:venue)
      }
      format.xml  { render :xml => @venue }
      format.json  { render :json => @venue, :callback => params[:callback] }
      format.ics  { ical_export(@venue) }
    end
  end

  # GET /venues/new
  # GET /venues/new.xml
  def new
    @venue = Venue.new
    @page_title = "Add a Venue"

    respond_to do |format|
      format.html { render :layout => !(params[:layout]=="false") }
      format.xml  { render :xml => @venue }
    end
  end

  # GET /venues/1/edit
  def edit
    @venue = Venue.find(params[:id])
    @page_title = "Editing '#{@venue.title}'"
  end

  # POST /venues
  # POST /venues.xml
  def create
    @venue = Venue.new(params[:venue])

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't create this venue because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && @venue.save
        flash[:success] = 'Venue was successfully created.'
        format.html { redirect_to( venue_path(@venue) ) }
        format.xml  { render :xml => @venue, :status => :created, :location => @venue }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @venue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /venues/1
  # PUT /venues/1.xml
  def update
    params[:venue][:latitude] = params[:venue][:longitude] = nil if params[:venue][:force_geocoding]=="1" unless params[:venue].blank?
    @venue = Venue.find(params[:id])
    
    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't update this venue because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && @venue.update_attributes(params[:venue])
        flash[:success] = 'Venue was successfully updated.'
        format.html { 
          if(!params[:from_event].blank?)
            redirect_to(event_url(params[:from_event]))
          else
            redirect_to( venue_path(@venue) )
          end
          }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @venue.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /venues/1
  # DELETE /venues/1.xml
  def destroy
    @venue = Venue.find(params[:id])

    if @venue.events.count > 0
      message = "Cannot destroy venue that has associated events, you must reassociate all its events first."
      respond_to do |format|
        format.html {
          flash[:failure] = message
          redirect_to( venue_path(@venue) )
        }
        format.xml {
          render :xml => message, :status => :unprocessable_entity
        }
      end
    else
      @venue.destroy
      respond_to do |format|
        format.html { redirect_to(venues_path, :flash => {:success => "\"#{@venue.title}\" has been deleted"}) }
        format.xml { head :ok }
      end
    end
  end

  # GET /venues/duplicates
  def duplicates
    @type = params[:type]
    begin
      @grouped_venues = Venue.find_duplicates_by_type(@type)
    rescue ArgumentError => e
      @grouped_venues = {}
      flash[:failure] = "#{e}"
    end

    @page_title = "Duplicate Venue Squasher"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grouped_venues }
    end
  end

protected

  def ical_export(venue)
    events = venue.events.order("start_time ASC").non_duplicates
    render(:text => Event.to_ical(events, :url_helper => lambda{|event| event_url(event)}), :mime_type => 'text/calendar')
  end
end
