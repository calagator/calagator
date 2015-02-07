class AddEventsCountToVenues < ActiveRecord::Migration
  def self.up
    add_column :venues, :events_count, :integer

    Calagator::Venue.reset_column_information
    Calagator::Venue.all.each do |p|
      Calagator::Venue.update_counters p.id, :events_count => p.events.length
    end
  end

  def self.down
    remove_column :venues, :events_count
  end
end
