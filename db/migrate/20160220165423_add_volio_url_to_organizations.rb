class AddVolioUrlToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :volio_url, :text
  end
end
