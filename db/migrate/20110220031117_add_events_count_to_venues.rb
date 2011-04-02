class AddEventsCountToVenues < ActiveRecord::Migration
  def self.up
    add_column :venues, :events_count, :integer

    Venue.reset_column_information
    Venue.find(:all).each do |p|
      Venue.update_counters p.id, :events_count => p.events.length
    end
  end

  def self.down
    remove_column :venues, :events_count
  end
end
