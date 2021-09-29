# frozen_string_literal: true

class AddEventsCountToVenues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :venues, :events_count, :integer
  end

  def self.down
    remove_column :venues, :events_count
  end
end
