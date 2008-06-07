# Table fields for 'books'
# - id
# - category_id
# - name
# - author

class Book < ActiveRecord::Base
  belongs_to :category
  acts_as_solr :include => [:category]
end