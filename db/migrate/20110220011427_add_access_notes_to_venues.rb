# frozen_string_literal: true

class AddAccessNotesToVenues < ActiveRecord::Migration[4.2]
  def self.up
    add_column :venues, :access_notes, :text
  end

  def self.down
    remove_column :venues, :access_notes
  end
end
