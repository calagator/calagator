class ChangeDurationToEndTime < ActiveRecord::Migration
  def self.up
    add_column :events, :end_time, :datetime
    remove_column :events, :duration
  end

  def self.down
    add_column :events, :duration, :integer
    remove_column :events, :end_time
  end
end
