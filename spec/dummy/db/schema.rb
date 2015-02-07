# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150206085809) do

  create_table "events", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "start_time"
    t.integer  "venue_id"
    t.string   "url"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "source_id"
    t.integer  "duplicate_of_id"
    t.datetime "end_time"
    t.string   "rrule"
    t.text     "venue_details"
  end

  create_table "sources", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.datetime "imported_at"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.boolean  "reimport"
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",        :null => false
    t.integer  "taggable_id",   :null => false
    t.string   "taggable_type", :null => false
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "venues", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "address"
    t.string   "url"
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.string   "street_address"
    t.string   "locality"
    t.string   "region"
    t.string   "postal_code"
    t.string   "country"
    t.decimal  "latitude",        :precision => 7, :scale => 4
    t.decimal  "longitude",       :precision => 7, :scale => 4
    t.string   "email"
    t.string   "telephone"
    t.integer  "source_id"
    t.integer  "duplicate_of_id"
    t.boolean  "closed",                                        :default => false
    t.boolean  "wifi",                                          :default => false
    t.text     "access_notes"
    t.integer  "events_count"
  end

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
