class SiteController < ApplicationController
  # Raise exception, mostly for confirming that exception_notification works
  def omfg
    raise ArgumentError, "OMFG"
  end

  # Render something to help benchmark stack without the views
  def hello
    render :text => "hello"
  end

  def index
    @overview = Event::Overview.new
    respond_to do |format|
      format.html { }
      format.any  { redirect_to events_path(format: params[:format]) }
    end
    @events = Event.all
    @events_by_date = @events.group_by do |e|
      e.start_time.to_date
    end
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
  end

  # Displays the about page.
  def about; end

  def opensearch
    respond_to do |format|
      format.xml { render :content_type => 'application/opensearchdescription+xml' }
    end
  end

  def defunct
  end
end
