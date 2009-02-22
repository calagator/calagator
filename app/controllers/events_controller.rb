class EventsController < ApplicationController
  include SquashManyDuplicatesMixin # Provides squash_many_duplicates

  # GET /events
  # GET /events.xml
  def index
    order = params[:order] || 'date'
    order = \
      case order
        when 'date'
          'start_time'
        when 'name'
          'lower(events.title), start_time'
        when 'venue'
          'lower(venues.title), start_time'
        end

    default_start_date = Time.today
    default_end_date   = Time.today + 3.months
    begin
      @start_date = !params[:date].blank? ? Date.parse(params[:date][:start]) : default_start_date
      @end_date = !params[:date].blank? ? Date.parse(params[:date][:end]) : default_end_date
    rescue ArgumentError => e
      @start_date = default_start_date
      @end_date   = default_end_date
      flash[:failure] = "You tried to filter by an invalid date"
    end

    @events_deferred = lambda {
      params[:date] ?
        Event.find_by_dates(@start_date, @end_date, :order => order) :
        Event.find_future_events(:order => order)
    }
    @perform_caching = params[:order].blank? && params[:date].blank?

    @page_title = "Events"

    render_events(@events_deferred)
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    begin
      @event = Event.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      flash[:failure] = e.to_s
      return redirect_to(:action => :index)
    end

    if @event.duplicate?
      return redirect_to(event_path(@event.duplicate_of))
    end

    @page_title = @event.title
    @hcal = render_to_string :partial => 'list_item.html.erb',
        :locals => { :event => @event, :show_year => true }

    # following used by Show so that weekday is rendered
    @show_hcal = render_to_string :partial => 'hcal.html.erb',
        :locals => { :event => @event, :show_year => true }

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @event.to_xml(:include => :venue) }
      format.json { render :json => @event.to_json(:include => :venue), :callback => params[:callback] }
      format.ics { ical_export([@event]) }
    end
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new
    @page_title = "Add an Event"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    @page_title = "Editing '#{@event.title}'"
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])
    @event.associate_with_venue(params[:venue_name])
    has_new_venue = @event.venue && @event.venue.new_record?

    # TODO Catch parse errors in time values
    # TODO Replace this awful control with Chronic
    @event.start_time = Time.parse "#{params[:start_date]} #{params[:start_time]}"
    @event.end_time = Time.parse "#{params[:end_date]} #{params[:end_time]}"

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't create this event because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && @event.save
        flash[:success] = 'Your event was successfully created. '
        format.html {
          if has_new_venue && !params[:venue_name].blank?
            flash[:success] += " Please tell us more about where it's being held."
            redirect_to(edit_venue_url(@event.venue, :from_event => @event.id))
          else
            redirect_to(@event)
          end
        }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])
    @event.associate_with_venue(params[:venue_name])
    has_new_venue = @event.venue && @event.venue.new_record?

    @event.start_time = Time.parse "#{params[:start_date]} #{params[:start_time]}"
    @event.end_time = Time.parse "#{params[:end_date]} #{params[:end_time]}"

    if evil_robot = !params[:trap_field].blank?
      flash[:failure] = "<h3>Evil Robot</h3> We didn't update this event because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
    end

    respond_to do |format|
      if !evil_robot && @event.update_attributes(params[:event])
        flash[:success] = 'Event was successfully updated.'
        format.html {
          if has_new_venue && !params[:venue_name].blank?
            flash[:success] += "Please tell us more about where it's being held."
            redirect_to(edit_venue_url(@event.venue, :from_event => @event.id))
          else
            redirect_to(@event)
          end
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
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
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
    end
  end

  # GET /events/duplicates
  def duplicates
    @type = params[:type] || 'title'
    begin
      @grouped_events = Event.find_duplicates_by_type(@type)
    rescue ArgumentError => e
      @grouped_events = {}
      flash[:failure] = "#{e}"
    end

    @page_title = "Duplicate Event Squasher"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grouped_events }
    end
  end

  # Search!!!
  def search
    # TODO Refactor this method and move much of it to the record-managing
    # logic into a generalized Event::search method.

    @query = params[:query].with{blank? ? nil : self}
    @tag = params[:tag].with{blank? ? nil : self}
    @current = ["1", "true"].include?(params[:current].to_s) ? true : false
    @order = params[:order]

    if @order && @order == "score" && @tag
      flash[:failure] = "You cannot sort tags by score"
      @order = nil
    end

    if !@query && !@tag
      flash[:failure] = "You must enter a search query"
      return redirect_to(root_path)
    end

    if @query && @tag
      # TODO make it possible to search by tag and query simultaneously
      flash[:failure] = "You can't search by tag and query at the same time"
      return redirect_to(root_path)
    elsif @query
      @grouped_events = Event.search_grouped_by_currentness(@query, :order => @order, :skip_old => @current)
    elsif @tag
      if @order
        # TODO make it possible to order items when searching by tag
        flash[:failure] = "Sorry, you can't order events returned by a tag search yet"
        @order = nil
      end
      @grouped_events = Event.search_tag_grouped_by_currentness(@tag, :order => @order, :current => @current)
    end

    # setting @events so that we can reuse the index atom builder
    @events = @grouped_events[:past] + @grouped_events[:current]

    @page_title = "Search Results for '#{@query}'"

    render_events(@events)
  end

  def refresh_version
    @event = Event.find(params[:id])
    @event.revert_to(params[:version])
    render :partial => 'form', :locals => { :event => @event}
  end

protected

  # Export +events+ to an iCalendar file.
  def ical_export(events=nil)
    events = events || Event.find_future_events
    render(:text => Event.to_ical(events, :url_helper => lambda{|event| event_url(event)}), :mime_type => 'text/calendar')
  end

  # Render +events+ for a particular format.
  def render_events(events)
    respond_to do |format|
      format.html # *.html.erb
      format.kml  # *.kml.erb
      format.ics  { ical_export(yield_events(events)) }
      format.atom { render :template => 'events/index' }
      format.xml  { render :xml  => yield_events(events).to_xml(:include => :venue) }
      format.json { render :json => yield_events(events).to_json(:include => :venue), :callback => params[:callback] }
    end
  end

  # Return an array of Events from a +container+, which can either be an array
  # of Events or a lambda that returns an array of Events.
  def yield_events(container)
    return container.respond_to?(:call) ? container.call : container
  end

end
