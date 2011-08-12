class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    # We already have a Tag model with a name
    # create_table :tags do |t|
    #   t.string :name
    # end

    # We already have a Taggings model with tag_id, taggable_id and taggable_type
    # so we'll just add the tagger, context, and created_at columns.
    add_column :taggings, :tagger_id, :integer
    add_column :taggings, :tagger_type, :string
    add_column :taggings, :context, :string
    add_column :taggings, :created_at, :datetime

    # We need to set the context on all existing tags to "tags" for them to be recognized
    execute "UPDATE taggings SET context='tags' WHERE context IS NULL"

    # create_table :taggings do |t|
    #   t.references :tag

    #   # You should make sure that the column created is
    #   # long enough to store the required class names.
    #   t.references :taggable, :polymorphic => true
    #   t.references :tagger, :polymorphic => true

    #   t.string :context

    #   t.datetime :created_at
    # end

    remove_index :taggings, :column => ["tag_id", "taggable_id", "taggable_type"]
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end

  def self.down
    remove_index :taggings, :tag_id
    remove_index :taggings, :column => [:taggable_id, :taggable_type, :context]

    remove_column :taggings, :tagger_id
    remove_column :taggings, :tagger_type
    remove_column :taggings, :context
    remove_column :taggings, :created_at

    add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_tag_id_and_taggable_id_and_taggable_type", :unique => true

    # drop_table :taggings
    # drop_table :tags
  end
end
