class EventsController < ApplicationController
  # Provides #duplicates and #squash_many_duplicates
  include DuplicateChecking::ControllerActions

  # GET /events
  # GET /events.xml
  def index
    @start_date = date_or_default_for(:start)
    @end_date = date_or_default_for(:end)

    query = Event.non_duplicates.ordered_by_ui_field(params[:order]).includes(:venue, :tags)
    @events = params[:date] ?
                query.within_dates(@start_date, @end_date) :
                query.future

    @perform_caching = params[:order].blank? && params[:date].blank?

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
    @event = Event.new(params[:event])
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
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
    @event = Event.find(params[:id])
    create_or_update
  end

  def create_or_update
    saver = Event::Saver.new(@event, params)
    respond_to do |format|
      if saver.save
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
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url, :flash => {:success => "\"#{@event.title}\" has been deleted"}) }
      format.xml  { head :ok }
    end
  end

  # GET /events/search
  def search
    @search = Event::Search.new(params)

    flash[:failure] = @search.failure_message
    return redirect_to root_path if @search.hard_failure?

    # setting @events so that we can reuse the index atom builder
    @events = @search.events

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
      format.xml  { render :xml  => event.to_xml(:include => :venue) }
      format.json { render :json => event.to_json(:include => :venue), :callback => params[:callback] }
      format.ics  { render :ics  => [event] }
    end
  end

  # Render +events+ for a particular format.
  def render_events(events)
    respond_to do |format|
      format.html # *.html.erb
      format.kml  # *.kml.erb
      format.ics  { render :ics => events || Event.future.non_duplicates }
      format.atom { render :template => 'events/index' }
      format.xml  { render :xml  => events.to_xml(:include => :venue) }
      format.json { render :json => events.to_json(:include => :venue), :callback => params[:callback] }
    end
  end

  # Return the default start date.
  def default_start_date
    Time.zone.today
  end

  # Return the default end date.
  def default_end_date
    Time.zone.today + 3.months
  end

  # Return a date parsed from user arguments or a default date. The +kind+
  # is a value like :start, which refers to the `params[:date][+kind+]` value.
  # If there's an error, set an error message to flash.
  def date_or_default_for(kind)
    default = send("default_#{kind}_date")
    return default unless params[:date].present?

    Date.parse(params[:date][kind])
  rescue ArgumentError, TypeError
    append_flash :failure, "Can't filter by an invalid #{kind} date."
    default
  end
end
