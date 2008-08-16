#!/usr/bin/env ruby

require 'vpim/icalendar'
require 'test/unit'


# Sorry for the donkey patching...
module Enumerable
  def first
    find{true}
  end
end

include Vpim

Req_1 =<<___
BEGIN:VCALENDAR
METHOD:REQUEST
PRODID:-//Lotus Development Corporation//NONSGML Notes 6.0//EN
VERSION:2.0
X-LOTUS-CHARSET:UTF-8
BEGIN:VTIMEZONE
TZID:Pacific
BEGIN:STANDARD
DTSTART:19501029T020000
TZOFFSETFROM:-0700
TZOFFSETTO:-0800
RRULE:FREQ=YEARLY;BYMINUTE=0;BYHOUR=2;BYDAY=-1SU;BYMONTH=10
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:19500402T020000
TZOFFSETFROM:-0800
TZOFFSETTO:-0700
RRULE:FREQ=YEARLY;BYMINUTE=0;BYHOUR=2;BYDAY=1SU;BYMONTH=4
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
ATTENDEE;ROLE=CHAIR;PARTSTAT=ACCEPTED;CN="Gary Pope/Certicom"
 ;RSVP=FALSE:mailto:gpope@certicom.com
ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION
 ;CN="Mike Harvey/Certicom";RSVP=TRUE:mailto:MHarvey@certicom.com
ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE
 :mailto:rgallant@emilpost.certicom.com
ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION
 ;CN="Sam Roberts/Certicom";RSVP=TRUE:mailto:SRoberts@certicom.com
ATTENDEE;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION
 ;CN="Tony Walters/Certicom";RSVP=TRUE:mailto:TWalters@certicom.com
CLASS:PUBLIC
DTEND;TZID="Pacific":20040415T130000
DTSTAMP:20040319T205045Z
DTSTART;TZID="Pacific":20040415T120000
ORGANIZER;CN="Gary Pope/Certicom":mailto:gpope@certicom.com
SEQUENCE:0
SUMMARY:hjold intyel
TRANSP:OPAQUE
UID:3E19204063C93D2388256E5C006BF8D9-Lotus_Notes_Generated
X-LOTUS-BROADCAST:FALSE
X-LOTUS-CHILD_UID:3E19204063C93D2388256E5C006BF8D9
X-LOTUS-NOTESVERSION:2
X-LOTUS-NOTICETYPE:I
X-LOTUS-UPDATE-SEQ:1
X-LOTUS-UPDATE-WISL:$S:1;$L:1;$B:1;$R:1;$E:1
END:VEVENT
END:VCALENDAR
___

Rep_1 =<<___
BEGIN:VCALENDAR
CALSCALE:GREGORIAN
PRODID:-//Apple Computer\, Inc//iCal 1.5//EN
VERSION:2.0
METHOD:REPLY
BEGIN:VEVENT
ATTENDEE;CN="Sam Roberts/Certicom";PARTSTAT=ACCEPTED;ROLE=REQ-PARTICIPAN
 T;RSVP=TRUE:mailto:SRoberts@certicom.com
CLASS:PUBLIC
DTEND;TZID=Pacific:20040415T130000
DTSTAMP:20040319T205045Z
DTSTART;TZID=Pacific:20040415T120000
ORGANIZER;CN="Gary Pope/Certicom":mailto:gpope@certicom.com
SEQUENCE:0
SUMMARY:hjold intyel
TRANSP:OPAQUE
UID:3E19204063C93D2388256E5C006BF8D9-Lotus_Notes_Generated
X-LOTUS-BROADCAST:FALSE
X-LOTUS-CHILDUID:3E19204063C93D2388256E5C006BF8D9
X-LOTUS-NOTESVERSION:2
X-LOTUS-NOTICETYPE:I
X-LOTUS-UPDATE-SEQ:1
X-LOTUS-UPDATE-WISL:$S:1\;$L:1\;$B:1\;$R:1\;$E:1
END:VEVENT
END:VCALENDAR
___

class TestIcal < Test::Unit::TestCase

  def assert_time(expected, actual, msg = nil)
    assert_in_delta(expected, actual, 1, msg)
  end

  # Reported by Kyle Maxwell
  def test_serialize_todo
icstodo =<<___
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTODO
END:VTODO
END:VCALENDAR
___

    cal = Icalendar.decode(icstodo)
    assert_equal(icstodo, cal.to_s)
  end

  # Tracker #18920
  def test_recurring_todos
icstodo =<<___
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VTODO
SUMMARY:todo
DTSTART:20040415T120000
RRULE:FREQ=WEEKLY;COUNT=2
END:VTODO
END:VCALENDAR
___

    cal = Icalendar.decode(icstodo).first
    todo = cal.todos.first
    assert(todo)
    assert_equal(todo.occurrences.to_a.size, 2)
  end

  def test_1
    req = Icalendar.decode(Req_1).first

    req.components { }
    req.components(Icalendar::Vevent) { }
    req.components(Icalendar::Vjournal) { }
    assert_equal(1, req.components.size)
    assert_equal(1, req.components(Icalendar::Vevent).size)
    assert_equal(0, req.components(Icalendar::Vjournal).size)

    assert_equal(req.protocol, 'REQUEST')

    event = req.events.first

    assert(event)

    assert( event.attendee?('mailto:sroberts@certicom.com'))
    assert(!event.attendee?('mailto:sroberts@uniserve.com'))

    me = event.attendees('mailto:sroberts@certicom.com').first

    assert(me)
    assert(me == 'mailto:sroberts@certicom.com')

    reply = Icalendar.create_reply

    reply.push(event.accept(me))

    # puts "Reply=>"
    # puts reply.to_s
  end

  def test_hal1
    # Hal was encoding raw strings, here's how to do it with the API.

    cal = Icalendar.create
    
    start = Time.now

    event = Icalendar::Vevent.create(start,
      'DTEND'    => start + 60 * 60,
      'SUMMARY'  => "this is an event",
      'RRULE'    =>  'freq=monthly;byday=2fr,4fr;count=5'
      )

    cal.push event

    #puts cal.encode
  end

  # FIXME - test bad durations, like 'PT1D'

  def test_event_duration
    now = Time.now
    event = Icalendar::Vevent.create(now)
    assert_time(now, event.dtstart)
    assert_nil(event.duration)
    assert_nil(event.dtend)

    event = Icalendar::Vevent.create(Date.new(2000, 1, 21),
                                    'DURATION' => 'PT1H')
    assert_equal(Time.gm(2000, 1, 21, 1),  event.dtend)

    event = Icalendar::Vevent.create(Date.new(2000, 1, 21),
                                    'DTEND' => Date.new(2000, 1, 22))
    assert_equal(24*60*60, event.duration)
  end

  def test_todo_duration
    todo = Icalendar::Vtodo.create()
    assert_nil(todo.dtstart)
    assert_nil(todo.duration)
    assert_nil(todo.due)

    todo = Icalendar::Vtodo.create('DTSTART' => Date.new(2000, 1, 21),
                                    'DURATION' => 'PT1H')
    assert_equal(Time.gm(2000, 1, 21, 1),  todo.due)

    todo = Icalendar::Vtodo.create('DTSTART' => Date.new(2000, 1, 21),
                                    'DUE' => Date.new(2000, 1, 22))
    assert_equal(24*60*60, todo.duration)
  end

  def test_journal_create
    vj = Icalendar::Vjournal.create('DESCRIPTION' => "description")
    assert_equal("description", vj.description)
  end

  def TODO_test_occurrence_with_date_start
    d = Date.new(2000, 1, 21)
    event = Icalendar::Vevent.create(d)
    d1 = event.occurences.to_a.first
    assert_equal(d.class, d1.class)
  end

  def test_decode_duration_four_weeks
    assert_equal 4*7*86400, Icalendar.decode_duration('P4W')
  end

  def test_decode_duration_negative_two_weeks
    assert_equal(-2*7*86400, Icalendar.decode_duration('-P2W'))
  end

  def test_decode_duration_five_days
    assert_equal 5*86400, Icalendar.decode_duration('P5D')
  end

  def test_decode_duration_one_hour
    assert_equal 3600, Icalendar.decode_duration('PT1H')
  end

  def test_decode_duration_five_minutes
    assert_equal 5*60, Icalendar.decode_duration('PT5M')
  end

  def test_decode_duration_ten_seconds
    assert_equal 10, Icalendar.decode_duration('PT10S')
  end

  def test_decode_duration_with_leading_plus
    assert_equal 10, Icalendar.decode_duration('+PT10S')
  end

  def test_decode_duration_with_composite_duration
    assert_equal((15*86400+5*3600+20), Icalendar.decode_duration('P15DT5H0M20S'))
  end

  def test_create_with_prodid
    prodid = "me//here/non-sgml"
    cal = Icalendar.create2(prodid) do |cal|
      assert_respond_to(cal, :push)
    end
    assert_equal(prodid, cal.producer)
  end

  def test_occurences
    t0 = Time.now
    vc = Icalendar.create2 do |vc|
      vc.add_event do |ve|
        ve.dtstart t0
      end
    end
    ve = vc.components(Icalendar::Vevent).first
    assert_time(t0, ve.occurences.select{true}.first)
    ve.occurences do |t|
      assert_time(t0, t)
    end

    vc = Icalendar.decode(<<__).first
BEGIN:VCALENDAR
BEGIN:VEVENT
END:VEVENT
END:VCALENDAR
__
    ve = vc.components(Icalendar::Vevent).first
    assert_raises(ArgumentError) { ve.occurences }
  end

  def test_each
    vc = Icalendar.decode(<<__).first
BEGIN:VCALENDAR
BEGIN:VEVENT
END:VEVENT
BEGIN:VTODO
END:VTODO
BEGIN:VJOURNAL
END:VJOURNAL
BEGIN:VTIMEZONE
END:VTIMEZONE
BEGIN:X-UNKNOWN
END:X-UNKNOWN
END:VCALENDAR
__
    count = Hash.new(0)

    vc.each do |c| count[c.class] += 1 end

    assert_equal(3, count.size)
    count.each do |_,v| assert_equal(1, v) end

    count = Hash.new(0)
    vc.events do |c| count[c.class] += 1 end
    vc.todos do |c| count[c.class] += 1 end
    vc.journals do |c| count[c.class] += 1 end
    assert_equal(3, count.size)
    count.each do |_,v| assert_equal(1, v) end

    assert_equal(3, vc.each.to_a.size)
    assert_equal(1, vc.each.select{|c| Vpim::Icalendar::Vevent === c}.size)
    assert_equal(1, vc.each.select{|c| Vpim::Icalendar::Vtodo === c}.size)
    assert_equal(1, vc.each.select{|c| Vpim::Icalendar::Vjournal === c}.size)

    assert_equal(1, vc.events.to_a.size)
    assert_equal(1, vc.todos.to_a.size)
    assert_equal(1, vc.journals.to_a.size)
    
    vc.to_s # Shouldn't raise...
    # TODO - encode isn't round-tripping, unknown components are lost, which is
    # not good.
  end

  def test_calscale
    req = Icalendar.decode(<<__).first
BEGIN:VCALENDAR
END:VCALENDAR
__
    assert_equal("GREGORIAN", req.calscale)
    req = Icalendar.decode(<<__).first
BEGIN:VCALENDAR
CALSCALE:GREGORIAN
END:VCALENDAR
__
    assert_equal("GREGORIAN", req.calscale)
  end

  def test_version
    req = Icalendar.decode(<<__).first
BEGIN:VCALENDAR
END:VCALENDAR
__
    assert_raises(InvalidEncodingError) { req.version }

    req = Icalendar.decode(<<__).first
BEGIN:VCALENDAR
VERSION:2.0
END:VCALENDAR
__
    assert_equal(20, req.version)
  end

  def test_protocol
    req = Icalendar.decode(<<__).first
BEGIN:VCALENDAR
METHOD:GET
END:VCALENDAR
__
    assert(req.protocol?("get"))
    assert(!req.protocol?("set"))
  end

  def test_transparency
    transparency = Icalendar.decode(<<__).first.to_a.first.transparency
BEGIN:VCALENDAR
BEGIN:VEVENT
END:VEVENT
END:VCALENDAR
__
    assert_equal("OPAQUE", transparency, "check default")

    transparency = Icalendar.decode(<<__).first.to_a.first.transparency
BEGIN:VCALENDAR
BEGIN:VEVENT
TRANSP:Opaque
END:VEVENT
END:VCALENDAR
__
    assert_equal("OPAQUE", transparency, "check opaque")

    transparency = Icalendar.decode(<<__).first.to_a.first.transparency
BEGIN:VCALENDAR
BEGIN:VEVENT
TRANSP:TrANSPARENT
END:VEVENT
END:VCALENDAR
__
    assert_equal("TRANSPARENT", transparency, "check transparent")

  end

  def test_event_maker_w_rrule
    vc = Icalendar.create2 do |vc|
      vc.add_event do |m|
        m.add_rrule("freq=monthly")
        m.set_rrule do |_| _.frequency = "daily" end
      end
    end
    assert_no_match(/RRULE:FREQ=MONTHLY/, vc.to_s)
    assert_match(/RRULE:FREQ=DAILY/, vc.to_s)
  end

end

