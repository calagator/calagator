class CreateVersionedEvents < ActiveRecord::Migration
  # NOTE: This migration's contents have been commented-out because they relied
  # on the old +acts_as_versioned+ plugin that has since replaced with the
  # +papertrail+ plugin.

  def self.up
###     Event.create_versioned_table do |t|
###       t.string   "title"
###       t.text     "description"
###       t.datetime "start_time"
###       t.string   "url"
###       t.datetime "created_at"
###       t.datetime "updated_at"
###       t.integer  "venue_id"
###       t.integer  "source_id"
###       t.integer  "duplicate_of_id"
###       t.datetime "end_time"
###       t.integer  "version"
###     end
  end

  def self.down
###     Event.drop_versioned_table
  end
end
