# frozen_string_literal: true

class RemoveNextUpdateFromSource < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :sources, :next_update
  end

  def self.down
    add_column :sources, :next_update, :datetime
  end
end
