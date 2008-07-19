class AddSourceIdToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :source_id, :integer
  end

  def self.down
    remove_column :events, :source_id
  end
end
