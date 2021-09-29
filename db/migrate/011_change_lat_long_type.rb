# frozen_string_literal: true

class ChangeLatLongType < ActiveRecord::Migration[4.2]
  def self.up
    # :decimal is more precise than :float, and we need that for lat/long.
    change_column :venues, :latitude, :decimal, precision: 15, scale: 10
    change_column :venues, :longitude, :decimal, precision: 15, scale: 10
  end

  def self.down
    change_column :venues, :latitude, :float
    change_column :venues, :longitude, :float
  end
end
