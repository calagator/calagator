# frozen_string_literal: true

class AddDetailedFieldsToVenue < ActiveRecord::Migration[4.2]
  def self.up
    add_column :venues, :street_address, :string
    add_column :venues, :locality, :string
    add_column :venues, :region, :string
    add_column :venues, :postal_code, :string
    add_column :venues, :country, :string

    add_column :venues, :latitude, :float
    add_column :venues, :longitude, :float

    add_column :venues, :email, :string
    add_column :venues, :telephone, :string
  end

  def self.down
    remove_columns :venues, :street_address, :locality, :region, :postal_code, :country, :latitude, :longitude, :email, :telephone
  end
end
