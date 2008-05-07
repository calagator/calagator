namespace :sources do
  desc 'Get updates from our sources'
  task :update => :environment do
    ActiveRecord::Base.establish_connection
    
    now = DateTime.now
    next_update = now + 2.days

    sources = Source.find(:all, :order => "next_update",
      :conditions => ['reimport = ? and next_update < ?', true, now ])
    puts "Nothing to do" unless sources.size > 0

    sources.each do |source|
      puts "Polling #{source.name}"
      begin
        abstract_events = source.to_events
        msg = "Got #{abstract_events.size} abstract events"
        # do more here to turn these events into real events
      rescue Exception => e
        msg = e.to_s
      end
      source.next_update = next_update
      source.updates.create(:status => msg)
      source.save!
    end

    # get rid of log entries older than two weeks
    too_old = Time.now - 2.weeks
    Update.find(:all, :conditions => ['created_at < ?', too_old]).each do |u|
      u.destroy
    end
  end

  desc 'Show update status for each source'
  task :status => :environment do
    ActiveRecord::Base.establish_connection
    now = Time.now
    sources = Source.find(:all, :conditions => ['reimport = ?', true])
    sources.each do |source| 
      puts "#{source.name}:"
      last_poll = Update.find_by_source_id(source.id, :order => 'updated_at desc')
      if last_poll
        puts "  #{last_poll.created_at}: #{last_poll.status}"
      else
        puts "  no updates"
      end
      puts "  (#{"due now: " if source.next_update < now}next at #{source.next_update})"
    end
  end

  desc 'Prime all the sources for updating soon'
  task :prime => :environment do
    ActiveRecord::Base.establish_connection
    sources = Source.find(:all, :conditions => ['reimport = ?', true])
    sources.each do |source| 
      source.next_update = Time.now
      source.save!
    end
  end
end

