class AddClosedFlagToVenues < ActiveRecord::Migration
  def self.up
    add_column :venues, :closed, :boolean, :default => false
  end

  def self.down
    remove_column :venues, :closed
  end
end
