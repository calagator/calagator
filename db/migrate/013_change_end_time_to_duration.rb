class ChangeEndTimeToDuration < ActiveRecord::Migration
  def self.up
    add_column :events, :duration, :integer
    
    # convert events that have an end time
    events = Event.where("end_time IS NOT NULL")
    events.each do |event|
      raise "Events ends before it starts" if (event.read_attribute(:end_time) < event.start_time)
      event.duration = ((event.read_attribute(:end_time) - event.start_time) / 60).ceil
      event.save!
      puts "#{event.title}, Duration => #{event.duration}" 
    end
    
    remove_column :events, :end_time
  end

  def self.down
    add_column :events, :end_time, :datetime
    
    # convert events that have a duration
    events = Event.where("duration IS NOT NULL")
    events.each do |event|
      event.set_attribute(:end_time, event.start_time + (event.duration * 60))
      event.save!
    end
    
    remove_column :events, :duration
  end
end
