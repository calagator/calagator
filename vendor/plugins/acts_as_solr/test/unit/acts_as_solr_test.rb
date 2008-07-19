require "#{File.dirname(File.expand_path(__FILE__))}/../test_helper"

class ActsAsSolrTest < Test::Unit::TestCase
  
  fixtures :books, :movies, :electronics, :postings
  
  # Inserting new data into Solr and making sure it's getting indexed
  def test_insert_new_data
    assert_equal 2, Book.count_by_solr('ruby OR splinter OR bob')
    b = Book.create(:name => "Fuze in action", :author => "Bob Bobber", :category_id => 1)
    assert b.valid?
    assert_equal 3, Book.count_by_solr('ruby OR splinter OR bob')
  end

  # Testing basic solr search:
  #  Model.find_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_find_by_solr_ruby
    ['ruby', 'dummy', 'name:ruby', 'name:dummy', 'name:ruby AND author:peter', 
      'author:peter AND ruby', 'peter dummy'].each do |term|
      records = Book.find_by_solr term
      assert_equal 1, records.total
      assert_equal "Peter McPeterson", records.docs.first.author
      assert_equal "Ruby for Dummies", records.docs.first.name
      assert_equal ({"id" => 2, 
                      "category_id" => 2, 
                      "name" => "Ruby for Dummies", 
                      "author" => "Peter McPeterson"}), records.docs.first.attributes
    end
  end
  
  # Testing basic solr search:
  #   Model.find_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_find_by_solr_splinter
    ['splinter', 'name:splinter', 'name:splinter AND author:clancy', 
      'author:clancy AND splinter', 'cell tom'].each do |term|
      records = Book.find_by_solr term
      assert_equal 1, records.total
      assert_equal "Splinter Cell", records.docs.first.name
      assert_equal "Tom Clancy", records.docs.first.author
      assert_equal ({"id" => 1, "category_id" => 1, "name" => "Splinter Cell", 
                     "author" => "Tom Clancy"}), records.docs.first.attributes
    end
  end
  
  # Testing basic solr search:
  #   Model.find_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_find_by_solr_ruby_or_splinter
    ['ruby OR splinter', 'ruby OR author:tom', 'name:cell OR author:peter', 'dummy OR cell'].each do |term|
      records = Book.find_by_solr term
      assert_equal 2, records.total
    end
  end
  
  # Testing search in indexed field methods:
  # 
  # class Movie < ActiveRecord::Base
  #   acts_as_solr :fields => [:name, :description, :current_time]
  # 
  #   def current_time
  #     Time.now.to_s
  #   end
  # 
  # end
  # 
  # The method current_time above gets indexed as being part of the
  # Movie model and it's available for search as well
  def test_find_with_dynamic_fields
    date = Time.now.strftime('%b %d %Y')
    ["dynamite AND #{date}", "description:goofy AND #{date}", "goofy napoleon #{date}", 
      "goofiness #{date}"].each do |term|
      records = Movie.find_by_solr term 
      assert_equal 1, records.total
      assert_equal ({"id" => 1, "name" => "Napoleon Dynamite", 
                     "description" => "Cool movie about a goofy guy"}), records.docs.first.attributes
    end
  end
  
  # Testing basic solr search that returns just the ids instead of the objects:
  #   Model.find_id_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_find_id_by_solr_ruby
    ['ruby', 'dummy', 'name:ruby', 'name:dummy', 'name:ruby AND author:peter', 
      'author:peter AND ruby'].each do |term|
      records = Book.find_id_by_solr term
      assert_equal 1, records.docs.size
      assert_equal [2], records.docs
    end
  end
  
  # Testing basic solr search that returns just the ids instead of the objects:
  #   Model.find_id_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_find_id_by_solr_splinter
    ['splinter', 'name:splinter', 'name:splinter AND author:clancy', 
      'author:clancy AND splinter'].each do |term|
      records = Book.find_id_by_solr term
      assert_equal 1, records.docs.size
      assert_equal [1], records.docs
    end
  end
  
  # Testing basic solr search that returns just the ids instead of the objects:
  #   Model.find_id_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_find_id_by_solr_ruby_or_splinter
    ['ruby OR splinter', 'ruby OR author:tom', 'name:cell OR author:peter', 
      'dummy OR cell'].each do |term|
      records = Book.find_id_by_solr term
      assert_equal 2, records.docs.size
      assert_equal [1,2], records.docs
    end
  end
  
  # Testing basic solr search that returns the total number of records found:
  #   Model.find_count_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_count_by_solr
    ['ruby', 'dummy', 'name:ruby', 'name:dummy', 'name:ruby AND author:peter', 
      'author:peter AND ruby'].each do |term|
      assert_equal 1, Book.count_by_solr(term), "there should only be 1 result for search: #{term}"
    end
  end
  
  # Testing basic solr search that returns the total number of records found:
  #   Model.find_count_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_count_by_solr_splinter
    ['splinter', 'name:splinter', 'name:splinter AND author:clancy', 
      'author:clancy AND splinter', 'author:clancy cell'].each do |term|
      assert_equal 1, Book.count_by_solr(term)
    end
  end
  
  # Testing basic solr search that returns the total number of records found:
  #   Model.find_count_by_solr 'term'
  # Note that you're able to mix free-search with fields and boolean operators
  def test_count_by_solr_ruby_or_splinter
    ['ruby OR splinter', 'ruby OR author:tom', 'name:cell OR author:peter', 'dummy OR cell'].each do |term|
      assert_equal 2, Book.count_by_solr(term)
    end
  end
    
  # Testing basic solr search with additional options:
  # Model.find_count_by_solr 'term', :limit => 10, :offset => 0
  def test_find_with_options
    [1,2].each do |count|
      records = Book.find_by_solr 'ruby OR splinter', :limit => count
      assert_equal count, records.docs.size
    end
  end
  
  # Testing self.rebuild_solr_index
  # - It makes sure the index is rebuilt after a data has been lost
  def test_rebuild_solr_index
    assert_equal 1, Book.count_by_solr('splinter')
    
    Book.find(:first).solr_destroy
    assert_equal 0, Book.count_by_solr('splinter')
    
    Book.rebuild_solr_index
    assert_equal 1, Book.count_by_solr('splinter')
  end
  
  # Testing instance methods:
  # - solr_save
  # - solr_destroy
  def test_solr_save_and_solr_destroy
    assert_equal 1, Book.count_by_solr('splinter')
  
    Book.find(:first).solr_destroy
    assert_equal 0, Book.count_by_solr('splinter')
    
    Book.find(:first).solr_save
    assert_equal 1, Book.count_by_solr('splinter')
  end
  
  # Testing the order of results
  def test_find_returns_records_in_order
    records = Book.find_by_solr 'ruby^5 OR splinter'
    # we boosted ruby so ruby should come first
  
    assert_equal 2, records.total
    assert_equal 'Ruby for Dummies', records.docs.first.name
    assert_equal 'Splinter Cell', records.docs.last.name    
  end
  
  # Testing solr search with optional :order argument
  def _test_with_order_option
    records = Movie.find_by_solr 'office^5 OR goofiness'
    assert_equal 'Hypnotized dude loves fishing but not working', records.docs.first.description
    assert_equal 'Cool movie about a goofy guy', records.docs.last.description
    
    records = Movie.find_by_solr 'office^5 OR goofiness', :order => 'description asc'
    assert_equal 'Cool movie about a goofy guy', records.docs.first.description
    assert_equal 'Hypnotized dude loves fishing but not working', records.docs.last.description
  end
  
  # Testing search with omitted :field_types should 
  # return the same result set as if when we use it
  def test_omit_field_types_in_search
    records  = Electronic.find_by_solr "price:[200 TO 599.99]"
    assert_match(/599/, records.docs.first.price)
    assert_match(/319/, records.docs.last.price)
    
    records  = Electronic.find_by_solr "price:[200 TO 599.99]", :order => 'price asc'
    assert_match(/319/, records.docs.first.price)
    assert_match(/599/, records.docs.last.price)
    
  end
  
  # Test to make sure the result returned when no matches
  # are found has the same structure when there are results
  def test_returns_no_matches
    records = Book.find_by_solr 'rubyist'
    assert_equal [], records.docs
    assert_equal 0, records.total
    
    records = Book.find_id_by_solr 'rubyist'
    assert_equal [], records.docs
    assert_equal 0, records.total
    
    records = Book.find_by_solr 'rubyist', :facets => {}
    assert_equal [], records.docs
    assert_equal 0, records.total
    assert_equal({"facet_fields"=>[]}, records.facets)
  end
  
  
  # Testing the :exclude_fields option when set in the
  # model to make sure it doesn't get indexed
  def test_exclude_fields_option
    records = Electronic.find_by_solr 'audiobooks OR latency'
    assert records.docs.empty?
    assert_equal 0, records.total
  
    assert_nothing_raised{
      records = Electronic.find_by_solr 'features:audiobooks'
      assert records.docs.empty?
      assert_equal 0, records.total
    }
  end
  
  # Testing the :auto_commit option set to false in the model
  # should not send the commit command to Solr
  def test_auto_commit_turned_off
    assert_equal 0, Author.count
    Author.create(:name => 'Tom Clancy', :biography => 'Writes novels of adventure and espionage')
    assert_equal 1, Author.count
    records = Author.find_by_solr 'tom clancy'
    assert_equal 0, records.total
  end
  
  # Testing models that use a different key as the primary key
  def test_search_on_model_with_string_id_field
    records = Posting.find_by_solr 'first^5 OR second'
    assert_equal 2, records.total
    assert_equal 'ABC-123', records.docs.first.guid
    assert_equal 'DEF-456', records.docs.last.guid
  end
  
  # Making sure the result set is ordered correctly even on
  # models that use a different key as the primary key
  def test_records_in_order_on_model_with_string_id_field
    records = Posting.find_by_solr 'first OR second^5'
    assert_equal 2, records.total
    assert_equal 'DEF-456', records.docs.first.guid
    assert_equal 'ABC-123', records.docs.last.guid
  end
  
  # Making sure the records are added when passing a batch size
  # to rebuild_solr_index
  def test_using_rebuild_solr_index_with_batch
    assert_equal 2, Movie.count_by_solr('office OR napoleon')
    Movie.find(:all).each(&:solr_destroy)
    assert_equal 0, Movie.count_by_solr('office OR napoleon')
    
    Movie.rebuild_solr_index 100
    assert_equal 2, Movie.count_by_solr('office OR napoleon')
  end
  
  # Making sure find_by_solr with scores actually return the scores
  # for each individual record
  def test_find_by_solr_with_score
    books = Book.find_by_solr 'ruby^10 OR splinter', :scores => true
    assert_equal 2, books.total
    assert_equal 0.50338805, books.max_score
    
    books.records.each { |book| assert_not_nil book.solr_score }
    assert_equal 0.50338805, books.docs.first.solr_score
    assert_equal 0.23058894, books.docs.last.solr_score
  end
  
  # Making sure nothing breaks when html entities are inside
  # the content to be indexed; and on the search as well.
  def test_index_and_search_with_html_entities
    description = "
    inverted exclamation mark  	&iexcl;  	&#161;
    ¤ 	currency 	&curren; 	&#164;
    ¢ 	cent 	&cent; 	&#162;
    £ 	pound 	&pound; 	&#163;
    ¥ 	yen 	&yen; 	&#165;
    ¦ 	broken vertical bar 	&brvbar; 	&#166;
    § 	section 	&sect; 	&#167;
    ¨ 	spacing diaeresis 	&uml; 	&#168;
    © 	copyright 	&copy; 	&#169;
    ª 	feminine ordinal indicator 	&ordf; 	&#170;
    « 	angle quotation mark (left) 	&laquo; 	&#171;
    ¬ 	negation 	&not; 	&#172;
    ­ 	soft hyphen 	&shy; 	&#173;
    ® 	registered trademark 	&reg; 	&#174;
    ™ 	trademark 	&trade; 	&#8482;
    ¯ 	spacing macron 	&macr; 	&#175;
    ° 	degree 	&deg; 	&#176;
    ± 	plus-or-minus  	&plusmn; 	&#177;
    ² 	superscript 2 	&sup2; 	&#178;
    ³ 	superscript 3 	&sup3; 	&#179;
    ´ 	spacing acute 	&acute; 	&#180;
    µ 	micro 	&micro; 	&#181;
    ¶ 	paragraph 	&para; 	&#182;
    · 	middle dot 	&middot; 	&#183;
    ¸ 	spacing cedilla 	&cedil; 	&#184;
    ¹ 	superscript 1 	&sup1; 	&#185;
    º 	masculine ordinal indicator 	&ordm; 	&#186;
    » 	angle quotation mark (right) 	&raquo; 	&#187;
    ¼ 	fraction 1/4 	&frac14; 	&#188;
    ½ 	fraction 1/2 	&frac12; 	&#189;
    ¾ 	fraction 3/4 	&frac34; 	&#190;
    ¿ 	inverted question mark 	&iquest; 	&#191;
    × 	multiplication 	&times; 	&#215;
    ÷ 	division 	&divide; 	&#247
        &hearts; &diams; &clubs; &spades;"
    
    author = Author.create(:name => "Test in Action&trade; - Copyright &copy; Bob", :biography => description)
    assert author.valid?
    author.solr_commit

    author = Author.find_by_solr 'trademark &copy &#190 &iexcl &#163'
    assert_equal 1, author.total
  end
  
  def test_operator_search_option
    assert_nothing_raised {
      books = Movie.find_by_solr "office napoleon", :operator => :or
      assert_equal 2, books.total
      
      books = Movie.find_by_solr "office napoleon", :operator => :and
      assert_equal 0, books.total
    }
    
    assert_raise RuntimeError do
      Movie.find_by_solr "office napoleon", :operator => :bad
    end
  end  
  
  # Making sure find_by_solr with scores actually return the scores
  # for each individual record and orders them accordingly
  def test_find_by_solr_order_by_score
    books = Book.find_by_solr 'ruby^10 OR splinter', {:scores => true, :order => 'score asc' }
    assert_equal 0.23058894, books.docs.first.solr_score
    assert_equal 0.50338805, books.docs.last.solr_score
    
    books = Book.find_by_solr 'ruby^10 OR splinter', {:scores => true, :order => 'score desc' }
    assert_equal 0.50338805, books.docs.first.solr_score
    assert_equal 0.23058894, books.docs.last.solr_score
  end
  
  # Search based on fields with the :date format
  def test_indexed_date_field_format
    movies = Movie.find_by_solr 'time_on_xml:[NOW-1DAY TO NOW]'
    assert_equal 2, movies.total
  end
end
