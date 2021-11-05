# frozen_string_literal: true

class AddVenueDetailsToEvents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :events, :venue_details, :text
  end

  def self.down
    remove_column :events, :venue_details
  end
end
