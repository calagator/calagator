# frozen_string_literal: true

class AddDuplicateOfColumnToEvents < ActiveRecord::Migration[4.2]
  def self.up
    add_column :events, :duplicate_of_id, :integer
  end

  def self.down
    remove_column :events, :duplicate_of_id
  end
end
