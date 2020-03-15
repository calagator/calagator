# frozen_string_literal: true

class AddLockedStatusToEvents < ActiveRecord::Migration
  def change
    add_column :events, :locked, :boolean, default: false
  end
end
