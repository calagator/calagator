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
  end
  
  # Displays the about page.
  def about; end
  
  # Export the database
  def export
    respond_to do |format|
      format.html
      format.sqlite3 do
        send_file(Rails.root.join($database_yml_struct.database), :filename => File.basename($database_yml_struct.database))
      end
      format.data do
        require "lib/data_marshal"
        target = Rails.root.join('tmp','dumps','current.data')
        DataMarshal.dump_cached(target)
        send_file(target)
      end
    end
  end

  def opensearch
    respond_to do |format|
      format.xml { render :content_type => 'application/opensearchdescription+xml' }
    end
  end
end
