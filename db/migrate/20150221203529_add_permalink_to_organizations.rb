class AddPermalinkToOrganizations < ActiveRecord::Migration
  def change
    change_table :organizations do |t|
      t.string :permalink, null: false, index: true, default: 'secret'
    end
  end
end
