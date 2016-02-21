class ChangeEventsMinimumAgeToString < ActiveRecord::Migration
  def up
    change_column :events, :minimum_age, :text
  end

  def down
  end
end
