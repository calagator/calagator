# frozen_string_literal: true

class Cleanup < ActiveRecord::Migration[4.2]
  # Remove obsolete tables and columns that may have been left behind by other migrations.
  def self.up
    if ActiveRecord::Base.connection.columns('venues').map(&:name).include?('version')
      remove_column :venues, :version
    end

    %w[event_versions venue_versions].each do |table|
      drop_table table if ActiveRecord::Base.connection.tables.include?(table)
    end
  end
end
