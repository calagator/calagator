class HomeController < ApplicationController
  def index
    @events_today = Event.find(:all,
      :conditions => { :start_time => Time.today..(Time.today + 1.days) },
      :order => 'start_time ASC',
      :limit => 6)
    @events_tomorrow = Event.find(:all,
      :conditions => { :start_time => (Time.today + 1.days)..(Time.today + 2.days) },
      :order => 'start_time ASC',
      :limit => 5)
    @events_later = Event.find(:all,
      :conditions => { :start_time => (Time.today + 2.days)..(Time.today + 7.days) },
      :order => 'start_time ASC',
      :limit => 5)
    @recently_added_events = Event.find(:all,
      :conditions => ['start_time >= ? AND id NOT IN (?)', Time.today, (@events_today+@events_tomorrow+@events_later).map(&:id)],
      :order => 'start_time ASC',
      :limit => 8)
  end

  # Used by #export
  Mime::Type.register "application/sqlite3", :sqlite3

  # Export the database
  def export
    respond_to do |format|
      format.html
      format.sqlite3 do
        send_file(File.join(RAILS_ROOT, $database_yml_struct.database), :filename => File.basename($database_yml_struct.database))
      end
    end
  end
end
