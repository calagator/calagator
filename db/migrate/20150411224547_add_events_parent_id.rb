class AddEventsParentId < ActiveRecord::Migration
  def up
    add_column :events, :parent_id, :integer, index: true
  end

  def down
    remove_column :events, :parent_id
  end
end
