require "recaptcha/rails"
require "calagator/duplicate_checking"
require "calagator/duplicate_checking/controller_actions"

module Calagator

class EventsController < Calagator::ApplicationController
  # Provides #duplicates and #squash_many_duplicates
  include Calagator::DuplicateChecking::ControllerActions
  require_admin only: [:duplicates, :squash_many_duplicates]

  before_filter :find_and_redirect_if_locked, :only => [:edit, :update, :destroy]

  # GET /events
  # GET /events.xml
  def index
    @browse = Event::Browse.new(params)
    @events = @browse.events
    @browse.errors.each { |error| append_flash :failure, error }
    render_events @events
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])
    return redirect_to(@event.progenitor) if @event.duplicate?

    render_event @event
  rescue ActiveRecord::RecordNotFound => e
    return redirect_to events_path, flash: { failure: e.to_s }
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new(params.permit![:event])
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new
    create_or_update
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    create_or_update
  end

  def create_or_update
    saver = Event::Saver.new(@event, params.permit!)
    respond_to do |format|
      if recaptcha_verified?(@event) && saver.save
        format.html {
          flash[:success] = 'Event was successfully saved.'
          if saver.has_new_venue?
            flash[:success] += " Please tell us more about where it's being held."
            redirect_to edit_venue_url(@event.venue, from_event: @event.id)
          else
            redirect_to @event
          end
        }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html {
          flash[:failure] = saver.failure
          render action: @event.new_record? ? "new" : "edit"
        }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url, :flash => {:success => "\"#{@event.title}\" has been deleted"}) }
      format.xml  { head :ok }
    end
  end

  # GET /events/search
  def search
    @search = Event::Search.new(params)

    # setting @events so that we can reuse the index atom builder
    @events = @search.events

    flash[:failure] = @search.failure_message
    return redirect_to root_path if @search.hard_failure?

    render_events(@events)
  end

  def clone
    @event = Event::Cloner.clone(Event.find(params[:id]))
    flash[:success] = "This is a new event cloned from an existing one. Please update the fields, like the time and description."
    render "new"
  end

  private

  def render_event(event)
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => event.to_xml(root: "events", :include => :venue) }
      format.json { render :json => event.to_json(:include => :venue) }
      format.ics  { render :ics  => [event] }
    end
  end

  # Render +events+ for a particular format.
  def render_events(events)
    respond_to do |format|
      format.html # *.html.erb
      format.kml  # *.kml.erb
      format.ics  { render :ics => events || Event.future.non_duplicates }
      format.atom { render :template => 'calagator/events/index' }
      format.xml  { render :xml  => events.to_xml(root: "events", :include => :venue) }
      format.json { render :json => events.to_json(:include => :venue) }
    end
  end

  def find_and_redirect_if_locked
    @event = Event.find(params[:id])
    if @event.locked?
      flash[:failure] = "You are not permitted to modify this event."
      redirect_to root_path
    end
  end
end

end
