require "calagator/duplicate_checking/controller_actions"

module Calagator

class VenuesController < Calagator::ApplicationController
  # Provides #duplicates and #squash_many_duplicates
  include DuplicateChecking::ControllerActions
  require_admin only: [:duplicates, :squash_many_duplicates]

  def venue
    @venue ||= params[:id] ? Venue.find(params[:id]) : Venue.new
  end


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
  def show
    Show.new(self).call
  end

  class Show < SimpleDelegator
    def call
      return if show_all_if_not_found
      return if ensure_progenitor
      respond_to do |format|
        format.html
        format.xml  { render xml: venue }
        format.json { render json: venue, callback: params[:callback] }
        format.ics  { render ics: venue.events.order("start_time ASC") }
      end
    end

    private

    def show_all_if_not_found
      return if venue
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      redirect_to venues_path
    end

    def ensure_progenitor
      return unless venue.duplicate?
      redirect_to venue.progenitor
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
  def create
    CreateOrUpdate.new(self).call
  end
  alias_method :update, :create

  class CreateOrUpdate < SimpleDelegator
    def call
      return if evil_robot?
      venue.attributes = params.permit![:venue].to_h
      venue.save ? render_success : render_failure
    end

    private

    def evil_robot?
      return unless params[:trap_field].present?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't save this venue because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
      render_failure
    end

    def render_success
      respond_to do |format|
        format.html { redirect_to from_event || venue, flash: { success: "Venue was successfully saved." } }
        format.xml  { render xml: venue, status: :created, location: venue }
      end
    end

    def render_failure
      respond_to do |format|
        format.html { render action: venue.new_record? ? "new" : "edit" }
        format.xml  { render xml: venue.errors, status: :unprocessable_entity }
      end
    end

    def from_event
      Event.find_by_id(params[:from_event])
    end
  end


  # DELETE /venues/1
  def destroy
    Destroy.new(self).call
  end

  class Destroy < SimpleDelegator
    def call
      return if prevent_destruction_of_venue_with_events
      venue.destroy
      respond_to do |format|
        format.html { redirect_to venues_path, flash: { success: %("#{venue.title}" has been deleted) } }
        format.xml  { head :ok }
      end
    end

    def prevent_destruction_of_venue_with_events
      return if venue.events.none?
      message = "Cannot destroy venue that has associated events, you must reassociate all its events first."
      respond_to do |format|
        format.html { redirect_to venue, flash: { failure: message } }
        format.xml  { render xml: message, status: :unprocessable_entity }
      end
    end
  end
end

end
