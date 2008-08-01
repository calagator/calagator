require 'facets/ruby'
require 'test/unit'

class TestEnumerableProduct < Test::Unit::TestCase

  def test_product
    a = %w|a b|
    b = %w|a x|
    c = %w|x y|
    z = a.product(b, c)
    r = [ ["a", "a", "x"],
          ["a", "a", "y"],
          ["a", "x", "x"],
          ["a", "x", "y"],
          ["b", "a", "x"],
          ["b", "a", "y"],
          ["b", "x", "x"],
          ["b", "x", "y"] ]
    assert_equal( r, z )
  end

end

