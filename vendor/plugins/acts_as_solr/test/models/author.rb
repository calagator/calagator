# Table fields for 'movies'
# - id
# - name
# - biography

class Author < ActiveRecord::Base

  acts_as_solr :auto_commit => false
  
end