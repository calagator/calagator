require File.join(File.dirname(__FILE__), '../test_helper')

class ActsAsSolrTest < Test::Unit::TestCase
  
  fixtures :books, :movies

  # Testing the multi_solr_search with the returning results being objects
  def test_multi_solr_search_return_objects
    records = Book.multi_solr_search "Napoleon OR Tom", :models => [Movie], :results_format => :objects
    assert_equal 2, records.total
    assert_equal Movie, records.docs.first.class
    assert_equal Book,  records.docs.last.class
  end
  
  # Testing the multi_solr_search with the returning results being ids
  def test_multi_solr_search_return_ids
    records = Book.multi_solr_search "Napoleon OR Tom", :models => [Movie], :results_format => :ids
    assert_equal 2, records.total
    assert records.docs.include?({"id" => "Movie:1"})
    assert records.docs.include?({"id" => "Book:1"})
  end
  
  # Testing the multi_solr_search with multiple models
  def test_multi_solr_search_multiple_models
    records = Book.multi_solr_search "Napoleon OR Tom OR Thriller", :models => [Movie, Category], :results_format => :ids
    assert_equal 4, records.total
    [{"id" => "Category:1"}, {"id" =>"Book:1"}, {"id" => "Movie:1"}, {"id" =>"Book:3"}].each do |result|
      assert records.docs.include?(result)
    end
  end
  
  # Testing empty result set format
  def test_returns_no_matches
    records = Book.multi_solr_search "not found", :models => [Movie, Category]
    assert_equal [], records.docs
    assert_equal 0, records.total
  end
  
end
