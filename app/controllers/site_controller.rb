class SiteController < ApplicationController

  def index
    # TODO Refactor this for clarity
    @events = {}
    @max_events_per_current_section = 10
    @min_events_per_later_section = (@max_events_per_current_section/2).round
    populate = lambda do |section, opts|
      leaf = {
        :count => Event.count(:conditions => opts[:conditions]),
        :results => Event.find(:all,
          :conditions => opts[:conditions],
          :limit => (opts[:limit] || @max_events_per_current_section),
          :order => (opts[:order] || 'start_time ASC')),
      }
      leaf[:skipped] = leaf[:count] - (leaf[:results].size || 0)
      @events[section] = leaf
    end
    populate[:today, {
      :conditions => ['(events.duplicate_of_id is NULL) AND
        (start_time > ? AND start_time < ?)', Time.today, (Time.today + 1.days)], 
      }]
    populate[:tomorrow, {
      :conditions => ['(events.duplicate_of_id is NULL) AND
        (start_time > ? AND start_time < ?)', (Time.today + 1.days), (Time.today + 2.days)],
      }]
    current_size = @events[:today][:results].size + @events[:today][:results].size
    populate[:later, {
      :conditions => ['(events.duplicate_of_id is NULL) AND
        (start_time > ? AND start_time < ?)', (Time.today + 2.days), (Time.today + 14.days)],
      :limit => current_size > @min_events_per_later_section ? current_size : @min_events_per_later_section}]
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
    	:light_green => 	'#bcf794',
    	:dark_green => 		'#59a12d',
    	:creme => 				'#f9ffec',
    	:cyan => 					'#98f0f7',
    	:light_cyan =>    '#e8fbfe',
    	:teal =>          '#66baa9',
    	:light_grey => 		'#aaccaa',
    	:dark_grey => 		'#445544',
    	
    	# used for emphasis blocks of creme text
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
