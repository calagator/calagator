class SiteController < ApplicationController
  caches_action :style

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

  def style
    # check to see if the request is an allowed file, if not, 404 it
    if %w(base print ie).include?(params[:name])
      template = params[:name]
    else
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 and return
    end

    # define colors to be used in CSS
    @colors = {
      :green =>         '#82c555',
      :light_green =>   '#bcf794',
      :dark_green =>    '#59a12d',
      :creme =>         '#f9ffec',
      :cyan =>          '#98f0f7',
      :light_cyan =>    '#e8fbfe',
      :teal =>          '#66baa9',
      :light_grey =>    '#aaccaa',
      :dark_grey =>     '#445544',
      :red =>           '#C10F00',
      :light_red =>     '#F5DBD7',

      # used for emphasis in blocks of creme text
      :white =>         '#fff'
    }

    output = render_to_string(:template => "site/styles/#{template}.css.erb")
    # output.gsub!(/\/\*[^*]*\*+([^\/][^*]*\*+)*\//,'').gsub!(/$\s+/,'')

    respond_to do |format|
      format.css {
        render :text => output
      }
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
