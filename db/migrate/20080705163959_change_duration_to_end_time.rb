class ChangeDurationToEndTime < ActiveRecord::Migration
  def self.up
    add_column :events, :end_time, :datetime
    
    # convert events that have a duration
    events = Event.find(:all, :conditions => "duration IS NOT NULL")
    for event in events
      event.write_attribute(:end_time, event.start_time + (event.duration * 1.minute) )
      event.save!
      printf "." 
    end

    remove_column :events, :duration
  end

  def self.down
    add_column :events, :duration, :integer

  # convert events that have an end time
    events = Event.find(:all, :conditions => "end_time IS NOT NULL")
    for event in events
      raise "Events ends before it starts" if (event.read_attribute(:end_time) < event.start_time)
      event.duration = ( (event.read_attribute(:end_time) - event.start_time) / 1.minute).ceil
      event.save!
      printf "." 
    end
    
    remove_column :events, :end_time
  end
end
class ChangeDurationToEndTime < ActiveRecord::Migration
  def self.up
    add_column :events, :end_time, :datetime
    
    # convert events that have a duration
    events = Event.find(:all, :conditions => "duration IS NOT NULL")
    for event in events
      event.write_attribute(:end_time, event.start_time + (event.duration * 1.minute) )
      event.save!
      printf "." 
    end

    remove_column :events, :duration
  end

  def self.down
    add_column :events, :duration, :integer

  # convert events that have an end time
    events = Event.find(:all, :conditions => "end_time IS NOT NULL")
    for event in events
      raise "Events ends before it starts" if (event.read_attribute(:end_time) < event.start_time)
      event.duration = ( (event.read_attribute(:end_time) - event.start_time) / 1.minute).ceil
      event.save!
      printf "." 
    end
    
    remove_column :events, :end_time
  end
end
