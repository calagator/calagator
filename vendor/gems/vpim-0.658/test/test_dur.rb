#!/usr/bin/env ruby

require 'vpim/duration'
require 'test/unit'

include Vpim

class TestVpimDate < Test::Unit::TestCase

  def duration(d0, h0, m0, s0)
    # 3 hours, 2 mins, 39 secs
    d = Duration.secs(d0 * 24 * 60 * 60 + h0 * 60 * 60 + m0 * 60 + s0)

    assert_equal(d.secs,  d0 * 24 * 60 * 60 + h0 * 60 * 60 + m0 * 60 + s0)
    assert_equal(d.mins,  d0 * 24 * 60 + h0 * 60 + m0)
    assert_equal(d.hours, d0 * 24 + h0)
    assert_equal(d.days,  d0)
    assert_equal(d.by_hours, [d0*24 + h0, m0, s0])
    assert_equal(d.by_days,  [d0,     h0, m0, s0])

    h, m, s = d.by_hours

    assert_equal(h, h0 + d0*24)
    assert_equal(m, m0)
    assert_equal(s, s0)

    d, h, m, s = d.by_days

    assert_equal(d, d0)
    assert_equal(h, h0)
    assert_equal(m, m0)
    assert_equal(s, s0)
  end

  def test_1
    duration(0, 3, 2, 39)
    duration(5, 23, 39, 1)
  end

end

