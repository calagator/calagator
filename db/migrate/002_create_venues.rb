class CreateVenues < ActiveRecord::Migration
  def self.up
    create_table :venues do |t|
      t.string :title
      t.text :description
      t.string :address
      t.string :url

      t.timestamps
    end

  end

  def self.down
    drop_table :venues
  end
end
