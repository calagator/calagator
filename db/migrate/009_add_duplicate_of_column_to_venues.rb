# frozen_string_literal: true

class AddDuplicateOfColumnToVenues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :venues, :duplicate_of_id, :integer
  end

  def self.down
    remove_column :venues, :duplicate_of_id
  end
end
