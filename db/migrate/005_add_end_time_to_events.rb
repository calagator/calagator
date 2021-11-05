# frozen_string_literal: true

class AddEndTimeToEvents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :events, :end_time, :timestamp
  end

  def self.down
    remove_column :events, :end_time
  end
end
