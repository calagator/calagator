class AddVenueDetailsToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :venue_details, :text
  end

  def self.down
    remove_column :events, :venue_details
  end
end
