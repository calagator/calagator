# frozen_string_literal: true

class SpecifyVenuesLatitudeAndLongitudePrecision < ActiveRecord::Migration[4.2]
  def up
    change_column :venues, :latitude, :decimal, precision: 7, scale: 4
    change_column :venues, :longitude, :decimal, precision: 7, scale: 4
  end

  def down
    change_column :venues, :latitude, :decimal
    change_column :venues, :longitude, :decimal
  end
end
