class HomeController < ApplicationController
  def index
    # TODO Refactor this for clarity
    @events = {}
    @max_events_per_normal_section = 10
    populate = lambda do |section, opts|
      leaf = {
        :count => Event.count(:conditions => opts[:conditions]),
        :results => Event.find(:all,
          :conditions => opts[:conditions],
          :limit => (opts[:count] || @max_events_per_normal_section),
          :order => (opts[:order] || 'start_time ASC')),
      }
      leaf[:skipped] = leaf[:count] - (leaf[:results].size || 0)
      @events[section] = leaf
    end
    populate[:today, {
      :conditions => {:start_time => Time.today..(Time.today + 1.days)}}]
    populate[:tomorrow, {
      :conditions => {:start_time => (Time.today + 1.days)..(Time.today + 2.days)}}]
    populate[:later, {
      :conditions => {:start_time => (Time.today + 2.days)..(Time.today + 14.days)}}]
  end

  # Used by #export action
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
