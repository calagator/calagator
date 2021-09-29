# frozen_string_literal: true

class RemoveFormatTypeFromSource < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :sources, :format_type
  end

  def self.down
    add_column :sources, :format_type, :string
  end
end
