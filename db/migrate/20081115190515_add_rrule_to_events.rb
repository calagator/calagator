class AddRruleToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :rrule, :string
    add_column :event_versions, :rrule, :string 
  end

  def self.down
    remove_column :events, :rrule
    remove_column :event_versions, :rrule
  end
end
