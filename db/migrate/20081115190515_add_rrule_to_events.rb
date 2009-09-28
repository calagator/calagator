class AddRruleToEvents < ActiveRecord::Migration
  # NOTE: Some of this migration's contents have been commented-out because
  # they used tables created for the old +acts_as_versioned+ plugin that has
  # since replaced with the +papertrail+ plugin.

  def self.up
    add_column :events, :rrule, :string
###     add_column :event_versions, :rrule, :string 
  end

  def self.down
    remove_column :events, :rrule
###     remove_column :event_versions, :rrule
  end
end
