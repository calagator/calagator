class RemoveNextUpdateFromSource < ActiveRecord::Migration
  def self.up
    remove_column :sources, :next_update
  end

  def self.down
    add_column :sources, :next_update, :datetime
  end
end
