class AddDuplicateOfColumnToVenues < ActiveRecord::Migration
  def self.up
    add_column :venues, :duplicate_of_id, :integer
  end

  def self.down
    remove_column :venues, :duplicate_of_id
  end
end
