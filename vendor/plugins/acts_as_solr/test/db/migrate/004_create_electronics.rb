class CreateElectronics < ActiveRecord::Migration
  def self.up
    create_table :electronics, :force => true do |t|
      t.column :name, :string
      t.column :manufacturer, :string
      t.column :features, :string
      t.column :category, :string
      t.column :price, :string
    end
  end

  def self.down
    drop_table :electronics
  end
end
