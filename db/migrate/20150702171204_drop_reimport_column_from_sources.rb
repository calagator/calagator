class DropReimportColumnFromSources < ActiveRecord::Migration
  def self.up
    remove_column :sources, :reimport
  end

  def self.down
    add_column :sources, :reimport, :boolean
  end
end
