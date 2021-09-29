# frozen_string_literal: true

class AddClosedFlagToVenues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :venues, :closed, :boolean, default: false
  end

  def self.down
    remove_column :venues, :closed
  end
end
