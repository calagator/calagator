class CreatePostings < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE postings(`guid` varchar(20) NOT NULL PRIMARY KEY, `name` varchar(200), `description` text)"
  end

  def self.down
    drop_table :postings
  end
end
