class VenuesController < ApplicationController
  # Provides #duplicates and #squash_many_duplicates
  include DuplicateChecking::ControllerActions

  # GET /venues
  # GET /venues.xml
  def index
    @search = Venue::Search.new(params)
    @venues = @search.venues

    respond_to do |format|
      format.html # index.html.erb
      format.kml  # index.kml.erb
      format.xml  { render :xml  => @venues }
      format.json { render :json => @venues, :callback => params[:callback] }
      format.js   { render :json => @venues, :callback => params[:callback] }
    end
  end

  def autocomplete
    @venues = Venue
      .non_duplicates
      .in_business
      .where(["LOWER(title) LIKE ?", "%#{params[:term]}%".downcase])
      .order('LOWER(title)')

    respond_to do |format|
      format.json { render :json => @venues, :callback => params[:callback] }
    end
  end

  # GET /venues/map
  def map
    @venues = Venue.non_duplicates.in_business
  end

  # GET /venues/1
  # GET /venues/1.xml
  def show
    @venue = Venue.find(params[:id], include: :source)

    return redirect_to @venue.duplicate_of if @venue.duplicate?

    respond_to do |format|
      format.html
      format.xml  { render xml: @venue }
      format.json { render json: @venue, callback: params[:callback] }
      format.ics  { render ics: @venue.events.order("start_time ASC").non_duplicates }
    end

  rescue ActiveRecord::RecordNotFound => e
    flash[:failure] = e.to_s
    redirect_to venues_path
  end

  # GET /venues/new
  # GET /venues/new.xml
  def new
    @venue = Venue.new
    render layout: params[:layout] != "false"
  end

  # GET /venues/1/edit
  def edit
    @venue = Venue.find(params[:id])
  end

  # POST /venues
  # POST /venues.xml
  def create
    @venue = Venue.new
    create_or_update
  end

  # PUT /venues/1
  # PUT /venues/1.xml
  def update
    @venue = Venue.find(params[:id])
    create_or_update
  end

  def create_or_update
    @venue.attributes = params[:venue]
    respond_to do |format|
      if !evil_robot? && @venue.save
        format.html { redirect_to from_event || @venue, flash: { success: "Venue was successfully saved." } }
        format.xml  { render xml: @venue, status: :created, location: @venue }
      else
        format.html { render action: @venue.new_record? ? "new" : "edit" }
        format.xml  { render xml: @venue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /venues/1
  # DELETE /venues/1.xml
  def destroy
    @venue = Venue.find(params[:id])

    if @venue.events.any?
      message = "Cannot destroy venue that has associated events, you must reassociate all its events first."
      respond_to do |format|
        format.html { redirect_to @venue, flash: { failure: message } }
        format.xml  { render xml: message, status: :unprocessable_entity }
      end
    else
      @venue.destroy
      respond_to do |format|
        format.html { redirect_to venues_path, flash: { success: %("#{@venue.title}" has been deleted) } }
        format.xml  { head :ok }
      end
    end
  end

  private

  def evil_robot?
    if params[:trap_field].present?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't save this venue because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end
  end

  def from_event
    Event.find_by_id(params[:from_event])
  end
end
