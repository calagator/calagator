#!/usr/bin/env ruby

require 'vpim/date'
require 'vpim/time'
require 'test/unit'

class TestVpimDate < Test::Unit::TestCase

  def test_to_time
    # Need to test with DateTime, but I don't have that with ruby 1.6.
    assert_equal(Time.at(0), Date.new(1970, 1, 1).vpim_to_time)
    assert_equal(Time.at(24 * 60 * 60), Date.new(1970, 1, 2).vpim_to_time)
  end

  def test_date_weekstart
    assert_equal(Date.weekstart(2004, 01, 12, 'tu').to_s, Date.new(2004, 01,  6).to_s)
    assert_equal(Date.weekstart(2004, 01, 12, 'we').to_s, Date.new(2004, 01,  7).to_s)
    assert_equal(Date.weekstart(2004, 01, 12, 'th').to_s, Date.new(2004, 01,  8).to_s)
    assert_equal(Date.weekstart(2004, 01, 12, 'fr').to_s, Date.new(2004, 01,  9).to_s)
    assert_equal(Date.weekstart(2004, 01, 12, 'sa').to_s, Date.new(2004, 01, 10).to_s)
    assert_equal(Date.weekstart(2004, 01, 12, 'su').to_s, Date.new(2004, 01, 11).to_s)
    assert_equal(Date.weekstart(2004, 01, 12, 'mo').to_s, Date.new(2004, 01, 12).to_s)
  end

  def do_bywday(args, expect)
    # Rewrite 'string' weekday specifications.
    args = [ args[0], args[1], Date.str2wday(args[2]), args[3] ]
    date  = Date.bywday(*args)
    dates = DateGen.bywday(*args)
    need  = Date.new(*expect)

    assert_equal(date, need)

    # Date.bywday always produces a single date, so should the generator, in
    # this case.
    assert_equal(dates[0], need)
  end

  def test_bywday

    #                               2004                              
    # 
    #       January               February               March        
    #  S  M Tu  W Th  F  S   S  M Tu  W Th  F  S   S  M Tu  W Th  F  S
    #              1  2  3   1  2  3  4  5  6  7      1  2  3  4  5  6
    #  4  5  6  7  8  9 10   8  9 10 11 12 13 14   7  8  9 10 11 12 13
    # 11 12 13 14 15 16 17  15 16 17 18 19 20 21  14 15 16 17 18 19 20
    # 18 19 20 21 22 23 24  22 23 24 25 26 27 28  21 22 23 24 25 26 27
    # 25 26 27 28 29 30 31  29                    28 29 30 31
    # 
    do_bywday([2004,  1, 4,  1], [2004,  1,  1])
    do_bywday([2004,  1, 4,  2], [2004,  1,  8])
    do_bywday([2004,  1, 4, -1], [2004,  1, 29])
    do_bywday([2004,  1, 4, -2], [2004,  1, 22])
    do_bywday([2004,  1, 4, -5], [2004,  1,  1])
    do_bywday([2004,nil, 4,  1], [2004,  1,  1])
    do_bywday([2004,nil, 4,  2], [2004,  1,  8])
    do_bywday([2004,-12, 4,  1], [2004,  1,  1])
    do_bywday([2004,-12, 4,  2], [2004,  1,  8])
    do_bywday([2004,-12, 4, -1], [2004,  1, 29])
    do_bywday([2004,-12, 4, -2], [2004,  1, 22])
    do_bywday([2004,-12, 4, -5], [2004,  1,  1])

    do_bywday([2004,  1, "th",  1], [2004,  1,  1])
    do_bywday([2004,  1, "th",  2], [2004,  1,  8])
    do_bywday([2004,  1, "th", -1], [2004,  1, 29])
    do_bywday([2004,  1, "th", -2], [2004,  1, 22])
    do_bywday([2004,  1, "th", -5], [2004,  1,  1])
    do_bywday([2004,nil, "th",  1], [2004,  1,  1])
    do_bywday([2004,nil, "th",  2], [2004,  1,  8])
    do_bywday([2004,-12, "th",  1], [2004,  1,  1])
    do_bywday([2004,-12, "th",  2], [2004,  1,  8])
    do_bywday([2004,-12, "th", -1], [2004,  1, 29])
    do_bywday([2004,-12, "th", -2], [2004,  1, 22])
    do_bywday([2004,-12, "th", -5], [2004,  1,  1])

    #       October               November              December      
    #  S  M Tu  W Th  F  S   S  M Tu  W Th  F  S   S  M Tu  W Th  F  S
    #                 1  2      1  2  3  4  5  6            1  2  3  4
    #  3  4  5  6  7  8  9   7  8  9 10 11 12 13   5  6  7  8  9 10 11
    # 10 11 12 13 14 15 16  14 15 16 17 18 19 20  12 13 14 15 16 17 18
    # 17 18 19 20 21 22 23  21 22 23 24 25 26 27  19 20 21 22 23 24 25
    # 24 25 26 27 28 29 30  28 29 30              26 27 28 29 30 31
    # 31

    do_bywday([2004, -1, 4,  1], [2004, 12,  2])
    do_bywday([2004, -1, 4, -1], [2004, 12, 30])
    do_bywday([2004, -1, 4, -2], [2004, 12, 23])
    do_bywday([2004, -1, 4, -5], [2004, 12,  2])
    do_bywday([2004,nil, 4, -1], [2004, 12, 30])
    do_bywday([2004,nil, 4, -2], [2004, 12, 23])
    do_bywday([2004,nil, 4, -5], [2004, 12,  2])
    do_bywday([2004,nil, 4, -7], [2004, 11, 18])

  end

  def do_gen(args)
    assert_nothing_thrown do
      dates = DateGen.bywday(*args)
      dates.each do |d|
        assert_equal(args[0], d.year)
        if(args[1])
          mon = args[1]
          if mon < 0
            mon = 13 + args[1]
          end
          assert_equal(mon, d.mon)
        end
        assert_equal(args[2], d.wday)
      end
    end
  end

  def test_gen
    do_gen([2004,  12, 1])
    do_gen([2004,  -1, 1])
    do_gen([2004, nil, 1])
  end
end

