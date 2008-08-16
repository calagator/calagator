#!/usr/bin/env ruby

require 'test/unit'

require 'vpim/repo'
require 'vpim/view'

class TestView < Test::Unit::TestCase
  View = Vpim::View
  Icalendar = Vpim::Icalendar

  def _test_week_events(vc, kind)
    vc = Icalendar.decode(vc.to_s.gsub("EVENT", kind)).first

    vv = View.week vc

    reader = kind.downcase + "s"

    kind = "check against kind=" + kind + "<\n" + vv.to_s + ">\n"

    assert_no_match(/yesterday/, vv.to_s, kind)
    assert_no_match(/nextweek/, vv.to_s, kind)

    assert_equal(["starts tomorrow"], vv.send(reader).map{|ve| ve.summary}, kind)
  end

  def test_week_single
    now = Time.now
    yesterday = now - View::SECSPERDAY
    tomorrow  = now + View::SECSPERDAY
    nextweek  = now + View::SECSPERDAY * 8

    vc = Icalendar.create2 do |vc|
      %w{yesterday tomorrow nextweek}.each do |dtstart|
        vc.add_event do |ve|
          ve.dtstart eval(dtstart)
          ve.summary "starts #{dtstart}"
        end
      end
    end

    _test_week_events(vc, "EVENT")
    _test_week_events(vc, "TODO")
    _test_week_events(vc, "JOURNAL")
  end

  def test_week_recurring
    now = Time.now
    ago = now - View::SECSPERDAY * 2

    vc = Icalendar.create2 do |vc|
      vc.add_event do |ve|
        ve.dtstart ago
        ve.dtend   ago + View::SECSPERDAY / 2
        ve.add_rrule do |r|
          r.frequency = "daily"
        end
      end
    end

    vv = View.week vc

    assert_equal(1, vv.events.to_a.size)

    ve = vv.events{|e| break e}

    #p ve

    #puts "now=" + now.to_s

    ve.occurrences() do |t|
      p [now, t, t + ve.duration]
    end



  end
end

