class Category < ActiveRecord::Base
  attr_accessible :description, :name

  #Associations
  has_and_belongs_to_many :events
end
