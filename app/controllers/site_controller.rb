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
    @tags_deferred = lambda { Event.tag_counts_on(:tags, limit: 100, conditions: "tags_count >= 10").sort_by(&:name) }

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

  def defunct
  end
end
