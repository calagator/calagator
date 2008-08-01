require 'facets/hash/rekey.rb'
require 'test/unit'

class TestHashRekey < Test::Unit::TestCase

  def test_rekey
    foo = { :a=>1, :b=>2 }
    foo = foo.rekey(:c, :a)
    assert_equal( 1, foo[:c] )
    assert_equal( 2, foo[:b] )
    assert_equal( nil, foo[:a] )
  end

  def test_rekey!
    foo = { :a=>1, :b=>2 }
    foo.rekey!(:c, :a)
    assert_equal( 1, foo[:c] )
    assert_equal( 2, foo[:b] )
    assert_equal( nil, foo[:a] )
  end

  def test_rekey_with_block
    foo = { :a=>1, :b=>2 }
    foo = foo.rekey{ |k| k.to_s }
    assert_equal( 1, foo['a'] )
    assert_equal( 2, foo['b'] )
    assert_equal( nil, foo[:a] )
    assert_equal( nil, foo[:b] )
  end

  def test_rekey_with_block!
    foo = { :a=>1, :b=>2 }
    foo.rekey!{ |k| k.to_s }
    assert_equal( 1, foo['a'] )
    assert_equal( 2, foo['b'] )
    assert_equal( nil, foo[:a] )
    assert_equal( nil, foo[:b] )
  end

end

