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
    @times_to_events = Event.select_for_overview
    @tagcloud_items_deferred = lambda { ActsAsTaggableOn::Tag.for_tagcloud }

    respond_to do |format|
      format.html { } # Default
      format.any  { redirect_to(events_path(:format => params[:format])) }
    end
  end
  
  # Displays the about page.
  def about; end

  def opensearch
    respond_to do |format|
      format.xml { render :content_type => 'application/opensearchdescription+xml' }
    end
  end
end
