require 'facets/time/to_time'
require 'test/unit'

class TestStringToTime < Test::Unit::TestCase

  def test_to_time
    s = "2:31:15 PM"
    t = s.to_time
    assert_equal( 14, t.hour )
    assert_equal( 31, t.min )
    assert_equal( 15, t.sec )
  end

end


