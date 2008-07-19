# Table fields for 'movies'
# - guid
# - name
# - description

class Posting < ActiveRecord::Base

  set_primary_key 'guid'
  acts_as_solr({},{:primary_key_field => 'pk_s'})
  
end