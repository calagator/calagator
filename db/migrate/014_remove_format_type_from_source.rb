class RemoveFormatTypeFromSource < ActiveRecord::Migration
  def self.up
    remove_column :sources, :format_type
  end

  def self.down
    add_column :sources, :format_type, :string
  end
end
