class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.string :title
      t.text :description
      t.timestamp :start_time
      t.integer :venue_id
      t.string :url

      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
