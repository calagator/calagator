class RemoveUpdates < ActiveRecord::Migration
  def up
    drop_table :updates
  end

  def down
    create_table :updates do |t|
      t.integer "source_id"
      t.text    "status"
      t.timestamps
    end
  end
end
