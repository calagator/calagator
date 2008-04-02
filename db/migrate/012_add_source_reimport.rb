class AddSourceReimport < ActiveRecord::Migration
  def self.up
    add_column :sources, :reimport, :boolean
  end

  def self.down
    remove_column :sources, :reimport
  end
end
