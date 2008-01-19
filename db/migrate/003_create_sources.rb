class CreateSources < ActiveRecord::Migration
  def self.up
    create_table :sources do |t|
      t.string :title
      t.string :url
      t.string :format_type
      t.timestamp :imported_at

      t.timestamps
    end
  end

  def self.down
    drop_table :sources
  end
end
