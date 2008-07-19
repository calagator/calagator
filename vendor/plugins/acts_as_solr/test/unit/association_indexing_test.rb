require File.join(File.dirname(__FILE__), '../test_helper')

class AssociationIndexingTest < Test::Unit::TestCase
  
  fixtures :categories, :books 
  
  # Testing the association indexing with has_many:
  # 
  # class Category < ActiveRecord::Base
  #   has_many :books
  #   acts_as_solr :include => [:books]
  # end
  # 
  # Note that some of the search terms below are from the 'books'
  # table, but get indexed as being a part of Category
  def test_search_on_fields_in_has_many_association
    ['thriller', 'novel', 'splinter', 'clancy', 'tom clancy thriller'].each do |term|
      assert_equal 1, Category.count_by_solr(term), "expected one result: #{term}"
    end
  end
  
  # Testing the association indexing with belongs_to:
  # 
  # class Book < ActiveRecord::Base
  #   belongs_to :category
  #   acts_as_solr :include => [:category]
  # end
  # 
  # Note that some of the search terms below are from the 'categories'
  # table, but get indexed as being a part of Book
  def test_search_on_fields_in_belongs_to_association
    ['splinter', 'clancy', 'tom clancy thriller', 'splinter novel'].each do |term|
      assert_equal 1, Book.count_by_solr(term), "expected one result: #{term}"
    end
  end

end
