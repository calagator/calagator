# Table fields for 'electronics'
# - id
# - name
# - manufacturer
# - features
# - category
# - price

class Electronic < ActiveRecord::Base
  acts_as_solr :facets => [:category, :manufacturer],
               :fields => [:name, :manufacturer, :features, :category, {:price => {:type => :range_float, :boost => 10.0}}],
               :boost  => 5.0, 
               :exclude_fields => [:features]

  # The following example would also convert the :price field type to :range_float
  # 
  # acts_as_solr :facets => [:category, :manufacturer],
  #              :fields => [:name, :manufacturer, :features, :category, {:price => :range_float}],
  #              :boost  => 5.0
end
