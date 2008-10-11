class VenuesController < ApplicationController
  include SquashManyDuplicatesMixin # Provides squash_many_duplicates

  # GET /venues
  # GET /venues.xml
  def index
    params[:val] ||= ""
    @venues = Venue.find(:non_duplicates, :conditions => ["title LIKE ?", "%#{params[:val]}%"], :order => 'lower(title)')
    @page_title = "Venues"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @venues }
      format.js  { render :json => @venues }
      format.kml  # index.kml.erb
    end
  end

  # GET /venues/1
  # GET /venues/1.xml
  def show
    begin
      @venue = Venue.find(params[:id], :include => :source)
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to(:action => :index)
    end

    return redirect_to(venue_url(@venue.duplicate_of)) if @venue.duplicate?

    @page_title = @venue.title
    @events = @venue.find_future_events

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @venue }
      format.json  { render :json => @venue }
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
        format.html { redirect_to(@venue) }
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
            redirect_to(@venue)
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
    @venue.destroy

    respond_to do |format|
      format.html { redirect_to(venues_url) }
      format.xml  { head :ok }
    end
  end

  # GET /venues/duplicates
  def duplicates
    @type = params[:type] || 'title'
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
  
  def refresh_version
    @venue = Venue.find(params[:id])
    @venue.revert_to(params[:version])
    render :partial => 'form', :locals => { :venue => @venue}
  end
end
