require "calagator/duplicate_checking/controller_actions"

module Calagator

class VenuesController < Calagator::ApplicationController
  # Provides #duplicates and #squash_many_duplicates
  include DuplicateChecking::ControllerActions
  require_admin only: [:duplicates, :squash_many_duplicates]

  # GET /venues
  def index
    @search = Venue::Search.new(params.permit!)
    @venues = @search.venues

    flash[:failure] = @search.failure_message
    return redirect_to venues_path if @search.hard_failure?
    render_venues @venues
  end

  def render_venues venues
    respond_to do |format|
      format.html # index.html.erb
      format.kml  # index.kml.erb
      format.xml  { render xml:  venues }
      format.json { render json: venues, callback: params[:callback] }
      format.js   { render json: venues, callback: params[:callback] }
    end
  end
  private :render_venues

  # GET /autocomplete via AJAX
  def autocomplete
    @venues = Venue
      .non_duplicates
      .in_business
      .where(["LOWER(title) LIKE ?", "%#{params[:term]}%".downcase])
      .order('LOWER(title)')

    render json: @venues, callback: params[:callback]
  end

  # GET /venues/map
  def map
    @venues = Venue.non_duplicates.in_business
  end

  # GET /venues/1
  before_action :show_all_if_not_found, :ensure_progenitor, only: :show

  def show_all_if_not_found
    venue
  rescue ActiveRecord::RecordNotFound => e
    flash[:failure] = e.to_s
    redirect_to venues_path
    false
  end
  private :show_all_if_not_found

  def ensure_progenitor
    return unless venue.duplicate?
    redirect_to venue.progenitor
    false
  end
  private :ensure_progenitor

  def show
    respond_to do |format|
      format.html
      format.xml  { render xml: venue }
      format.json { render json: venue, callback: params[:callback] }
      format.ics  { render ics: venue.events.order("start_time ASC") }
    end
  end

  # GET /venues/new
  def new
    venue
    render layout: params[:layout] != "false"
  end

  # GET /venues/1/edit
  def edit
    venue
  end

  # POST /venues, # PUT /venues/1
  before_action :prevent_evil_robots, only: [:create, :update]

  def prevent_evil_robots
    return unless params[:trap_field].present?
    flash[:failure] = "<h3>Evil Robot</h3> We didn't save this venue because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    render_failure
    false
  end
  private :prevent_evil_robots

  def create
    venue.attributes = params.permit![:venue].to_h
    venue.save ? render_success : render_failure
  end
  alias_method :update, :create

  def render_success
    respond_to do |format|
      format.html { redirect_to from_event || venue, flash: { success: "Venue was successfully saved." } }
      format.xml  { render xml: venue, status: :created, location: venue }
    end
  end
  private :render_success

  def render_failure
    respond_to do |format|
      format.html { render action: venue.new_record? ? "new" : "edit" }
      format.xml  { render xml: venue.errors, status: :unprocessable_entity }
    end
  end
  private :render_failure

  def from_event
    Event.find_by_id(params[:from_event])
  end
  private :from_event

  # DELETE /venues/1
  before_action :prevent_destruction_of_venue_with_events, only: :destroy

  def prevent_destruction_of_venue_with_events
    return unless venue.events.any?

    message = "Cannot destroy venue that has associated events, you must reassociate all its events first."
    respond_to do |format|
      format.html { redirect_to venue, flash: { failure: message } }
      format.xml  { render xml: message, status: :unprocessable_entity }
    end
    false
  end
  private :prevent_destruction_of_venue_with_events

  def destroy
    venue.destroy
    respond_to do |format|
      format.html { redirect_to venues_path, flash: { success: %("#{venue.title}" has been deleted) } }
      format.xml  { head :ok }
    end
  end

  private

  def venue
    @venue ||= params[:id] ? Venue.find(params[:id]) : Venue.new
  end
end

end
