class AddDuplicateOfColumnToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :duplicate_of_id, :integer
  end

  def self.down
    remove_column :events, :duplicate_of_id
  end
end
