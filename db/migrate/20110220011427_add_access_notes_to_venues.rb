class AddAccessNotesToVenues < ActiveRecord::Migration
  def self.up
    add_column :venues, :access_notes, :text
  end

  def self.down
    remove_column :venues, :access_notes
  end
end
