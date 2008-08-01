require 'facets/array/product'
require 'test/unit'

class TC_Array_Product < Test::Unit::TestCase

  def test_op_product
    a = [1,2,3] ** [4,5,6]
    assert_equal( [[1, 4],[1, 5],[1, 6],[2, 4],[2, 5],[2, 6],[3, 4],[3, 5],[3, 6]], a )
  end

  #     def test_op_mod
  #       a = [:A,:B,:C]
  #       assert_equal( a[1], a/1 )
  #       assert_equal( :B, a/1 )
  #     end
  #
  #     def test_op_div
  #       a = [:A,:B,:C]
  #       assert_equal( a[1], a/1 )
  #       assert_equal( :B, a/1 )
  #     end

end


