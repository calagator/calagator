require 'facets/ruby.rb'
require 'test/unit'

class TC_Array < Test::Unit::TestCase

  #def test_product_01
  #  i = [[1,2], [4], ["apple", "banana"]]
  #  o = [[1, 4, "apple"], [1, 4, "banana"], [2, 4, "apple"], [2, 4, "banana"]]
  #  assert_equal( o, Enumerable.product(*i) )
  #end

  def test_product_02
    a = [1,2,3].product([4,5,6])
    assert_equal( [[1, 4],[1, 5],[1, 6],[2, 4],[2, 5],[2, 6],[3, 4],[3, 5],[3, 6]], a )
  end

  def test_product_03
    a = []
    [1,2,3].product([4,5,6]) {|elem| a << elem }
    assert_equal( [[1, 4],[1, 5],[1, 6],[2, 4],[2, 5],[2, 6],[3, 4],[3, 5],[3, 6]], a )
  end

end

class TC_Binding < Test::Unit::TestCase

  def setup
    x = "hello"
    @bind = binding
  end

  def test_eval
    assert_equal( "hello", @bind.eval("x") )
  end

end

class TC_Integer < Test::Unit::TestCase

  def test_even?
    (-100..100).step(2) do |n|
      assert(n.even? == true)
    end
    (-101..101).step(2) do |n|
      assert(n.even? == false)
    end
  end

  def test_odd?
    (-101..101).step(2) do |n|
      assert(n.odd? == true)
    end
    (-100..100).step(2) do |n|
      assert(n.odd? == false)
    end
  end

end

class Test_Symbol < Test::Unit::TestCase

  def test_to_proc
    x = (1..10).inject(&:*)
    assert_equal(3628800, x)

    x = %w{foo bar qux}.map(&:reverse)
    assert_equal(%w{oof rab xuq}, x)

    x = [1, 2, nil, 3, nil].reject(&:nil?)
    assert_equal([1, 2, 3], x)

    x = %w{ruby and world}.sort_by(&:reverse)
    assert_equal(%w{world and ruby}, x)
  end

  def test_to_proc_call
    assert_instance_of(Proc, up = :upcase.to_proc )
    assert_equal( "HELLO", up.call("hello") )
  end

  def test_to_proc_map
    q = [[1,2,3], [4,5,6], [7,8,9]].map(&:reverse)
    a = [[3, 2, 1], [6, 5, 4], [9, 8, 7]]
    assert_equal( a, q )
  end

end

class TC_Enumerable < Test::Unit::TestCase

  def test_count_01
    e = [ 'a', '1', 'a' ]
    assert_equal( 1, e.count('1') )
    assert_equal( 2, e.count('a') )
  end

  def test_count_02
    e = [ ['a',2], ['a',2], ['a',2], ['b',1] ]
    assert_equal( 3, e.count(['a',2]) )
  end

  def test_count_03
    e = { 'a' => 2, 'a' => 2, 'b' => 1 }
    assert_equal( 1, e.count('a',2) )
  end

  def test_one?
    a = [nil, true]
    assert( a.one? )
    a = [true, false]
    assert( a.one? )
    a = [true, true]
    assert( ! a.one? )
    a = [true, 1]
    assert( ! a.one? )
    a = [1, 1]
    assert( ! a.one? )
  end

  def test_none?
    a = [nil, nil]
    assert( a.none? )
    a = [false, false]
    assert( a.none? )
    a = [true, false]
    assert( ! a.none? )
    a = [nil, 1]
    assert( ! a.none? )
  end

  def test_group_by_for_array
    a = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    r = {0=>[0, 2, 4, 6, 8], 1=>[1, 3, 5, 7, 9]}
    assert_equal(r, a.group_by{|e| e%2}.each{|k, v| v.sort!})

    h = {0=>0, 1=>1, 2=>2, 3=>3, 4=>4, 5=>5, 6=>6, 7=>7, 8=>8, 9=>9}
    r = {0=>[[0, 0], [2, 2], [4, 4], [6, 6], [8, 8]], 1=>[[1, 1], [3, 3], [5, 5], [7, 7], [9, 9]]}
    assert_equal(r, h.group_by{|k, v| v%2}.each{|k, v| v.sort!})

    x = (1..5).group_by{ |n| n % 3 }
    o = { 0 => [3], 1 => [1, 4], 2 => [2,5] }
    assert_equal( o, x )

    x = ["I had", 1, "dollar and", 50, "cents"].group_by{ |e| e.class }
    o = { String => ["I had","dollar and","cents"], Fixnum => [1,50] }
    assert_equal( o, x )
  end

end

class TestNilClassConversion < Test::Unit::TestCase

  def test_to_f
    assert_equal( 0, nil.to_f )
  end

end

class TC_String < Test::Unit::TestCase

  def test_bytes
    s = "abc"
    assert_equal( s.unpack('C*'), s.bytes )
  end

  def test_chars
    assert_equal( ["a","b","c"], "abc".chars )
    assert_equal( ["a","b","\n","c"], "ab\nc".chars )
  end

  def test_lines
    assert_equal( ['a','b','c'], "a\nb\nc".lines )
  end


  def test_each_char
    a = []
    i = "this"
    i.each_char{ |w| a << w }
    assert_equal( ['t', 'h', 'i', 's'], a )
  end

end

class TestTimeConversion < Test::Unit::TestCase

  def test_to_date
    t = Time.now #parse('4/20/2005 15:37')
    assert_instance_of( ::Date, t.to_date )
  end

  def test_to_time
    t = Time.now #parse('4/20/2005 15:37')
    assert_instance_of( ::Time, t.to_time )
  end

end

