class CreateMovies < ActiveRecord::Migration
  def self.up
    create_table :movies, :force => true do |t|
      t.column :name, :string
      t.column :description, :string
    end
  end

  def self.down
    drop_table :movies
  end
end
