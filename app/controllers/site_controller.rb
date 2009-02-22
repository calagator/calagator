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
    @times_to_events_deferred = lambda { Event.select_for_overview }
  end
  
  # Displays the about page.
  def about; end
  
  def recent_changes
    events = Event.versioned_class.find(:all, :order => 'updated_at DESC', :limit => 10)
    venues = Venue.versioned_class.find(:all, :order => 'updated_at DESC', :limit => 10)
    @items = events.concat(venues).sort { |a,b| b.updated_at <=> a.updated_at  }
    
    respond_to do |format|
      format.html
      format.atom
    end
  end

  # Export the database
  def export
    respond_to do |format|
      format.html
      format.sqlite3 do
        send_file(File.join(RAILS_ROOT, $database_yml_struct.database), :filename => File.basename($database_yml_struct.database))
      end
      format.data do
        require "lib/data_marshal"
        target = "#{RAILS_ROOT}/tmp/dumps/current.data"
        DataMarshal.dump_cached(target)
        send_file(target)
      end
    end
  end
end
