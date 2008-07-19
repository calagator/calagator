class CreateAuthors < ActiveRecord::Migration
  def self.up
    create_table :authors, :force => true do |t|
      t.column :name, :string
      t.column :biography, :text
    end
  end

  def self.down
    drop_table :authors
  end
end
