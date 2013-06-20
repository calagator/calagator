class CreateCategoriesEvents < ActiveRecord::Migration
  def change
  	create_table :categories_events do |t|
  		t.references :category
  		t.references :event
  	end
  end

  def down
  end
end
