class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string         :title,          unique: true
      t.text           :description

      t.integer        :source_id

      t.string         :url
      t.string         :telephone
      t.string         :email

      t.timestamps
    end
  end
end
