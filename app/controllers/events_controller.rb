class EventsController < ApplicationController
  # GET /events
  # GET /events.xml

  def index
    order = params[:order] || 'date'
    order = case order
            when 'date'
              'start_time'
            when 'name'
              'lower(events.title), start_time'
            when 'venue'
              'lower(venues.title), start_time'
            end

    @start_date = params[:date] ? Date.parse(params[:date][:start]) : Date.today
    @end_date = params[:date] ? Date.parse(params[:date][:end]) : Date.today + 6.months
    @events = params[:date] ?
        Event.find_by_dates(@start_date, @end_date, order) :
        Event.find_future_events(:order => order)

    @page_title = "Events"

    respond_to do |format|
      format.html # index.html.erb
      format.kml  # index.kml.erb
      format.xml  { render :xml => @events }
      format.json { render :json => @events }
      format.ics  { ical_export() }
      format.atom # index.atom.builder
    end
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
      format.xml  { render :xml => @event }
      format.json { render :json => @event }
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

    respond_to do |format|
      if @event.update_attributes(params[:event])
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

    if @type == 'na'
      # Use find to get an Array of all non-duplicates in date order,
      # make it a Hash so it takes the same form as find_duplicates_by(:grouped => true)
      # so that the duplicate template will display it properly
      @grouped_events = { [] => Event.find_future_events }
    else
      @type = ['all','any'].include?(@type) ? @type.to_sym : @type.split(',')
      @grouped_events = Event.find_duplicates_by(@type, :grouped => true, :where => "a.start_time >= #{ActiveRecord::Base.connection.quote(Time.now - 1.day)}")
    end

    @page_title = "Duplicate Event Squasher"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grouped_events }
    end
  end

  # POST /events/squash_multiple_duplicates
  def squash_many_duplicates
    # TODO Extract common code between EventsController and VenuesController duplicate squasher
    master_event_id = params[:master_event_id].to_i
    duplicate_event_ids = params.keys.grep(/^duplicate_event_id_\d+$/){|t| params[t].to_i}

    squashed = Event.squash(:master => master_event_id, :duplicates => duplicate_event_ids)

    flash[:failure] = "The master event could not be squashed into itself." if duplicate_event_ids.include?(master_event_id)

    if squashed.size > 0
      message = "Squashed duplicates #{squashed.map {|obj| obj.title}} into master #{master_event_id}."
      flash[:success] = flash[:success].nil? ? message : flash[:success] + message
    else
      message = "No duplicates were squashed."
      flash[:failure] = flash[:failure].nil? ? message : flash[:failure] + message
    end

    redirect_to :action => "duplicates", :type => params[:type]
  end

  # Search!!!
  def search
    @query = params[:query]
    if @query.blank?
      flash[:failure] = "You must enter a search query"
      return redirect_to(root_path)
    end
    @grouped_events = Event.search_grouped_by_currentness(params[:query], :order => params[:order])
  end

protected

  # export events to an iCalendar file
  def ical_export(events=nil)
    events = events || Event.find_future_events
    render(:text => Event.to_ical(events, :url_helper => lambda{|event| event_url(event)}), :mime_type => 'text/calendar')
  end

end
