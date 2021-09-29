# frozen_string_literal: true

class CreateUpdates < ActiveRecord::Migration[4.2]
  def self.up
    create_table :updates do |t|
      t.integer 'source_id'
      t.text 'status'
      t.timestamps
    end
    add_column :sources, :next_update, :datetime
  end

  def self.down
    remove_column :sources, :next_update
    drop_table :updates
  end
end
