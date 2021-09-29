# frozen_string_literal: true

class AddWifiFlagToVenues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :venues, :wifi, :boolean, default: false
  end

  def self.down
    remove_column :venues, :wifi
  end
end
