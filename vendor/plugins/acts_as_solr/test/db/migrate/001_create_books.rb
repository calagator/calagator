class CreateBooks < ActiveRecord::Migration
  def self.up
    create_table :books, :force => true do |t|
      t.column :category_id, :integer
      t.column :name, :string
      t.column :author, :string
    end
  end

  def self.down
    drop_table :books
  end
end
