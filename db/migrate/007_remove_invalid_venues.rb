class RemoveInvalidVenues < ActiveRecord::Migration
  def self.up
    puts "Destroying invalid venues:"
    for venue in Venue.find(:all)
      if venue.read_attribute(:title).blank?
        puts "- #{venue.inspect}"
        venue.destroy
      end
    end
  end

  def self.down
  end
end
