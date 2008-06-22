class VenuesController < ApplicationController
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
      @venue = Venue.find(params[:id])
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

    respond_to do |format|
      if @venue.save
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
    params[:venue][:latitude] = params[:venue][:longitude] = nil if params[:venue][:force_geocoding]=="1"
    @venue = Venue.find(params[:id])

    respond_to do |format|
      if @venue.update_attributes(params[:venue])
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

    if @type == 'na'
      # Use find to get an Array of all non-duplicates in title order,
      # make it a Hash so it takes the same form as find_duplicates_by(:grouped => true)
      # so that the duplicate template will display it properly
      @grouped_venues = { [] => Venue.find(:non_duplicates, :order => :title) }
    else
      @type = ['all','any'].include?(@type) ? @type.to_sym : @type.split(',')
      @grouped_venues = Venue.find_duplicates_by(@type, :grouped => true)
    end

    @page_title = "Duplicate Venue Squasher"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grouped_venues }
    end
  end

  # POST /venues/squash_multiple_duplicates
  def squash_many_duplicates
    # TODO Extract common code between EventsController and VenuesController duplicate squasher
    master_venue_id = params[:master_venue_id].to_i
    duplicate_venue_ids = params.keys.grep(/^duplicate_venue_id_\d+$/){|t| params[t].to_i}

    squashed = Venue.squash(:master => master_venue_id, :duplicates => duplicate_venue_ids)

    flash[:failure] = "The master venue could not be squashed into itself." if duplicate_venue_ids.include?(master_venue_id)

    if squashed.size > 0
      message = "Squashed duplicates #{squashed.map {|obj| obj.title}} into master #{master_venue_id}."
      flash[:success] = flash[:success].nil? ? message : flash[:success] + message
    else
      message = "No duplicates were squashed."
      flash[:failure] = flash[:failure].nil? ? message : flash[:failure] + message
    end

    redirect_to :action => "duplicates", :type => params[:type]
  end
end
