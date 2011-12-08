class AddOrganizationIdToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :organization_id, :integer
  end

  def self.down
    remove_column :events, :organization_id
  end
end