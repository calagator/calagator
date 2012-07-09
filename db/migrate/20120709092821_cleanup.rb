class Cleanup < ActiveRecord::Migration
  # Remove obsolete tables and columns that may have been left behind by other migrations.
  def self.up
    if ActiveRecord::Base.connection.columns('venues').map(&:name).include?("version")
      remove_column :venues, :version
    end

    %w[event_versions venue_versions].each do |table|
      if ActiveRecord::Base.connection.tables.include?(table)
        drop_table table
      end
    end
  end

  def self.down
  end
end
