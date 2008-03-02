class EventsController < ApplicationController
  require 'vpim/icalendar'
  # GET /events
  # GET /events.xml
  def index
    @events = Event.find(:all, :conditions => [ 'start_time > ?', Date.today ], :order => 'start_time ASC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
      format.ics { ical_export() }
    end
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
      format.ics { ical_export([@event]) }
    end
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])

    respond_to do |format|
      if @event.save
        flash[:success] = 'Event was successfully created.'
        format.html { redirect_to(@event) }
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

    respond_to do |format|
      if @event.update_attributes(params[:event])
        flash[:success] = 'Event was successfully updated.'
        format.html { redirect_to(@event) }
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
  
  # export events to an iCalendar file
  def ical_export(events=nil)
    events = events || Event.find(:all)
    cal = Vpim::Icalendar.create2
    
    for event in events
      cal.add_event do |e|
        e.dtstart       event.start_time
        e.dtend         event.end_time || event.start_time+1.hour
        e.summary       event.title
        e.description   event.description
        e.url           event_url(event)
        e.created       event.created_at
        e.lastmod       event.updated_at
        #e.location      !event.venue.nil? ? event.venue.title : ''
      end
    end
    
    ics = cal.encode
    render :text => ics, :mime_type => 'text/calendar'
  end
  
end
