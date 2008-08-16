#!/usr/bin/env ruby

require 'vpim/vcard'
require 'test/unit'
require 'date'

require 'pp'

include Vpim

# Test equivalence where whitespace is compressed.
def assert_equal_nospace(expected, got)
  expected = expected.gsub(/\s+/,'')
  got = expected.gsub(/\s+/,'')
  assert_equal(expected, got)
end


# Test cases: multiple occurrences of type
=begin
begin:VCARD
version:2.1
v;x1=a;x2=,a;x3=a,;x4=a,,a;x5=,a,:
source:ldap://cn=bjorn%20Jensen, o=university%20of%20Michigan, c=US
fn:Bj=F8rn
  Jensen
other.name:Jensen;Bj=F8rn
some.other.value:1.2.3
some.other.value:some.other
some.other.value:some.other.value
v;p-1=;p-2=,,;p-3=a;p-4=a        b,"v;p-1=;p-2=,,;p-3=a;p-4=a":v-value
email;type=internet:
 bjorn@umich.edu
tel;type=work,voice,msg:+1 313 747-4454
tel:+...
key;type=x509;encoding=B:dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK
end:vcard
=end

class TestVcard < Test::Unit::TestCase

  # RFC2425 - 8.1. Example 1
  # Note that this is NOT a valid vCard, it lacks BEGIN/END.
  EX1 =<<'EOF'
cn:  
cn:Babs Jensen
cn:Barbara J Jensen
sn:Jensen
email:babs@umich.edu
phone:+1 313 747-4454
x-id:1234567890
EOF
  def test_ex1
    card = nil
    ex1 = EX1
    assert_nothing_thrown { card = Vpim::DirectoryInfo.decode(ex1) }
    assert_equal_nospace(EX1, card.to_s)

    assert_equal("Babs Jensen", card["cn"])
    assert_equal("Jensen",      card["sn"])

    assert_equal("babs@umich.edu", card[ "email" ])

    assert_equal("+1 313 747-4454", card[ "PhOnE" ])
    assert_equal("1234567890", card[ "x-id" ])
    assert_equal([], card.groups)
  end

  # RFC2425 - 8.2. Example 2
  EX2 = <<-END
begin:VCARD
source:ldap://cn=bjorn%20Jensen, o=university%20of%20Michigan, c=US
name:Bjorn Jensen
fn:Bj=F8rn Jensen
n:Jensen;Bj=F8rn
email;type=internet:bjorn@umich.edu
tel;type=work,voice,msg:+1 313 747-4454
key;type=x509;encoding=B:dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK
end:VCARD
  END

  def test_ex2
    card = nil
    ex2 = EX2
    assert_nothing_thrown { card = Vpim::Vcard.decode(ex2).first }
    assert_equal(EX2, card.encode(0))
    assert_raises(InvalidEncodingError) { card.version }

    assert_equal("Bj=F8rn Jensen", card.name.fullname)
    assert_equal("Jensen",  card.name.family)
    assert_equal("Bj=F8rn", card.name.given)
    assert_equal("",        card.name.prefix)

    assert_equal("Bj=F8rn Jensen", card[ "fn" ])
    assert_equal("+1 313 747-4454", card[ "tEL" ])

    assert_equal(nil, card[ "not-a-field" ])
    assert_equal([], card.groups)

    assert_equal(nil,          card.enum_by_name("n").entries[0].param("encoding"))

    assert_equal(["internet"], card.enum_by_name("Email").entries.first.param("Type"))
    assert_equal(nil,          card.enum_by_name("Email").entries[0].param("foo"))

    assert_equal(["B"],        card.enum_by_name("kEy").to_a.first.param("encoding"))
    assert_equal("B",          card.enum_by_name("kEy").entries[0].encoding)

    assert_equal(["work", "voice", "msg"], card.enum_by_name("tel").entries[0].param("Type"))

    assert_equal([card.fields[6]], card.enum_by_name("tel").entries)

    assert_equal([card.fields[6]], card.enum_by_name("tel").to_a)

    assert_equal(nil, card.enum_by_name("tel").entries.first.encoding)

    assert_equal("B", card.enum_by_name("key").entries.first.encoding)

    assert_equal("dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK", card.enum_by_name("key").entries.first.value_raw)

    assert_equal("this could be \nmy certificate\n", card.enum_by_name("key").entries.first.value)

    card.lines
  end

=begin
  EX3 = <<-END
begin:vcard
source:ldap://cn=Meister%20Berger,o=Universitaet%20Goerlitz,c=DE
name:Meister Berger
fn:Meister Berger
n:Berger;Meister
bday;value=date:1963-09-21
o:Universit=E6t G=F6rlitz
title:Mayor
title;language=de;value=text:Burgermeister
note:The Mayor of the great city of
  Goerlitz in the great country of Germany.
email;internet:mb@goerlitz.de
home.tel;type=fax,voice,msg:+49 3581 123456
home.label:Hufenshlagel 1234\n
 02828 Goerlitz\n
 Deutschland
key;type=X509;encoding=b:MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQ
 AwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bmljYXRpb25zI
 ENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0ZW1zMRwwGgYDVQQD
 ExNyb290Y2EubmV0c2NhcGUuY29tMB4XDTk3MDYwNjE5NDc1OVoXDTk3MTIwMzE5NDc
 1OVowgYkxCzAJBgNVBAYTAlVTMSYwJAYDVQQKEx1OZXRzY2FwZSBDb21tdW5pY2F0aW
 9ucyBDb3JwLjEYMBYGA1UEAxMPVGltb3RoeSBBIEhvd2VzMSEwHwYJKoZIhvcNAQkBF
 hJob3dlc0BuZXRzY2FwZS5jb20xFTATBgoJkiaJk/IsZAEBEwVob3dlczBcMA0GCSqG
 SIb3DQEBAQUAA0sAMEgCQQC0JZf6wkg8pLMXHHCUvMfL5H6zjSk4vTTXZpYyrdN2dXc
 oX49LKiOmgeJSzoiFKHtLOIboyludF90CgqcxtwKnAgMBAAGjNjA0MBEGCWCGSAGG+E
 IBAQQEAwIAoDAfBgNVHSMEGDAWgBT84FToB/GV3jr3mcau+hUMbsQukjANBgkqhkiG9
 w0BAQQFAAOBgQBexv7o7mi3PLXadkmNP9LcIPmx93HGp0Kgyx1jIVMyNgsemeAwBM+M
 SlhMfcpbTrONwNjZYW8vJDSoi//yrZlVt9bJbs7MNYZVsyF1unsqaln4/vy6Uawfg8V
 UMk1U7jt8LYpo4YULU7UZHPYVUaSgVttImOHZIKi4hlPXBOhcUQ==
end:vcard
  END
    assert_equal(
      ["other", "some.other"],
      card.groups_all
      )
    #a = []
    #card.enum_by_group("some.other").each { |field| a << field }
    #assert_equal(card.fields.indexes(6, 7, 8), a)
    #assert_equal(card.fields.indexes(6, 7, 8), card.fields_by_group("some.other"))
=end

  # This is my vCard exported from OS X's AddressBook.app.
  EX_APPLE1 =<<'EOF'
BEGIN:VCARD
VERSION:3.0
N:Roberts;Sam;;;
FN:Roberts Sam
EMAIL;type=HOME;type=pref:sroberts@uniserve.com
TEL;type=WORK;type=pref:905-501-3781
TEL;type=FAX:905-907-4230
TEL;type=HOME:416 535 5341
ADR;type=HOME;type=pref:;;376 Westmoreland Ave.;Toronto;ON;M6H 3
 A6;Canada
NOTE:CATEGORIES: Amis/Famille
BDAY;value=date:1970-07-14
END:VCARD
EOF
  def test_ex_apple1
    card = nil
    assert_nothing_thrown { card = Vpim::Vcard.decode(EX_APPLE1).first }

    assert_equal("Roberts Sam", card.name.fullname)
    assert_equal("Roberts",  card.name.family)
    assert_equal("Sam", card.name.given)
    assert_equal("",        card.name.prefix)
    assert_equal("",        card.name.suffix)

    assert_equal(EX_APPLE1, card.to_s(64))

    check_ex_apple1(card)
  end

NICKNAME0=<<'EOF'
begin:vcard
end:vcard
EOF
NICKNAME1=<<'EOF'
begin:vcard
nickname:
end:vcard
EOF
NICKNAME2=<<'EOF'
begin:vcard
nickname:      
end:vcard
EOF
NICKNAME3=<<'EOF'
begin:vcard
nickname:     Big Joey 
end:vcard
EOF
NICKNAME4=<<'EOF'
begin:vcard
nickname:    
nickname:     Big Joey 
end:vcard
EOF
NICKNAME5=<<'EOF'
begin:vcard
nickname:    
nickname:     Big Joey 
nickname:Bob
end:vcard
EOF
  def test_nickname
    assert_equal(nil,          Vpim::Vcard.decode(NICKNAME0).first.nickname)
    assert_equal(nil,          Vpim::Vcard.decode(NICKNAME1).first.nickname)
    assert_equal(nil,          Vpim::Vcard.decode(NICKNAME2).first.nickname)
    assert_equal('Big Joey',   Vpim::Vcard.decode(NICKNAME3).first.nickname)
    assert_equal('Big Joey',   Vpim::Vcard.decode(NICKNAME4).first['nickname'])
    assert_equal(['Big Joey', 'Bob'],   Vpim::Vcard.decode(NICKNAME5).first.nicknames)
  end


  def check_ex_apple1(card)
    assert_equal("3.0", card[ "version" ])
    assert_equal(30,    card.version)

    assert_equal("sroberts@uniserve.com",  card[ "email" ])
    assert_equal(["HOME", "pref"],         card.enum_by_name("email").entries.first.param("type"))
    assert_equal(nil,                      card.enum_by_name("email").entries.first.group)

    assert_equal(["WORK","pref"],  card.enum_by_name("tel").entries[0].param("type"))
    assert_equal(["FAX"],          card.enum_by_name("tel").entries[1].param("type"))
    assert_equal(["HOME"],         card.enum_by_name("tel").entries[2].param("type"))

    assert_equal(nil,              card.enum_by_name("bday").entries[0].param("type"))
    assert_equal(["date"],         card.enum_by_name("bday").entries[0].param("value"))

    assert_equal( 1970,            card.enum_by_name("bday").entries[0].to_time[0].year)
    assert_equal(    7,            card.enum_by_name("bday").entries[0].to_time[0].month)
    assert_equal(   14,            card.enum_by_name("bday").entries[0].to_time[0].day)

    assert_equal("CATEGORIES: Amis/Famille", card[ "note" ])
  end

  # Test data for Vpim.expand
  EX_EXPAND =<<'EOF'
BEGIN:a
a1:
BEGIN:b
BEGIN:c
c1:
c2:
END:c
V1:
V2:
END:b
a2:
END:a
EOF
  def test_expand
    src = Vpim.decode(EX_EXPAND)
    dst = Vpim.expand(src)

    assert_equal('a',   dst[0][0].value)
    assert_equal('A1',  dst[0][1].name)
    assert_equal('b',   dst[0][2][0].value)
    assert_equal('c',   dst[0][2][1][0].value)
    assert_equal('C1',  dst[0][2][1][1].name)
    assert_equal('C2',  dst[0][2][1][2].name)
    assert_equal('c',   dst[0][2][1][3].value)

    cards = Vpim::Vcard.decode(EX_APPLE1)

    assert_equal(1, cards.length)
    
    check_ex_apple1(cards[0])
  end

  # An iCalendar for Vpim.expand
  EX_ICAL_1 =<<'EOF'
BEGIN:VCALENDAR
CALSCALE:GREGORIAN
X-WR-TIMEZONE;VALUE=TEXT:Canada/Eastern
METHOD:PUBLISH
PRODID:-//Apple Computer\, Inc//iCal 1.0//EN
X-WR-RELCALID;VALUE=TEXT:18E75B8C-5722-11D7-AB0B-000393AD088C
X-WR-CALNAME;VALUE=TEXT:Events
VERSION:2.0
BEGIN:VEVENT
SEQUENCE:14
UID:18E74C28-5722-11D7-AB0B-000393AD088C
DTSTAMP:20030301T171521Z
SUMMARY:Bob Log III
DTSTART;TZID=Canada/Eastern:20030328T200000
DTEND;TZID=Canada/Eastern:20030328T230000
DESCRIPTION:Healey's\n\nLook up exact time.\n
BEGIN:VALARM
TRIGGER;VALUE=DURATION:-P2D
ACTION:DISPLAY
DESCRIPTION:Event reminder
END:VALARM
BEGIN:VALARM
ATTENDEE:mailto:sroberts@uniserve.com
TRIGGER;VALUE=DURATION:-P1D
ACTION:EMAIL
SUMMARY:Alarm notification
DESCRIPTION:This is an event reminder
END:VALARM
END:VEVENT
BEGIN:VEVENT
SEQUENCE:1
DTSTAMP:20030312T043534Z
SUMMARY:Small Potatoes 10\nFriday\, March 14th\, 8:00 p.m.\n361 Danforth 
 Avenue (at Hampton -- Chester subway)\nInfo:  (416) 480-2802 or (416) 
 323-1715\n
UID:18E750A8-5722-11D7-AB0B-000393AD088C
DTSTART;TZID=Canada/Eastern:20030315T000000
DURATION:PT1H
BEGIN:VALARM
ATTENDEE:mailto:sroberts@uniserve.com
TRIGGER;VALUE=DURATION:-P1D
ACTION:EMAIL
SUMMARY:Alarm notification
DESCRIPTION:This is an event reminder
END:VALARM
END:VEVENT
END:VCALENDAR
EOF
  def test_ical_1
    src = nil
    dst = nil
    assert_nothing_thrown {
      src = Vpim.decode(EX_ICAL_1)
      dst = Vpim.expand(src)
    }

    #p dst
  end

  # Constructed data.
  TST1 =<<'EOF'
BEGIN:vCard
DESCRIPTION:Healey's\n\nLook up exact time.\n
email;type=work:work@example.com
email;type=internet,home;type=pref:home@example.com
fax;type=foo,pref;bar:fax
name:firstname
name:secondname
time;value=time:
END:vCARD
EOF
  def _test_cons # FIXME
    card = nil
    assert_nothing_thrown { card = Vpim::Vcard.decode(TST1).first }
    assert_equal(TST1, card.to_s)
    assert_equal('Healey\'s\n\nLook up exact time.\n', card[ "description" ])

    # Test the [] API
    assert_equal(nil,         card[ "not-a-field" ])

    assert_equal('firstname', card[ "name" ])

    assert_equal('home@example.com', card[ "email" ])
    assert_equal('home@example.com', card[ "email", "pref" ])
    assert_equal('home@example.com', card[ "email", "internet" ])
    assert_equal('work@example.com', card[ "email", "work" ])


    # Test the merging of vCard 2.1 type fields.
    #p card
    #p card.enum_by_name('fax').entries[0].each_param { |p,v| puts "#{p} = #{v}\n" }

    assert_equal('fax', card[ "fax" ])
    assert_equal('fax', card[ "fax", 'bar' ])
  end

=begin
  def test_bad
    # FIXME: this should THROW, it's badly encoded!
    assert_nothing_thrown {
      Vpim::Vcard.decode(
      "BEGIN:VCARD\nVERSION:3.0\nKEYencoding=b:this could be \nmy certificate\n\nEND:VCARD\n"
      )
    }
  end
=end

  def test_create
    card = Vpim::Vcard.create

    key = Vpim::DirectoryInfo.decode("key;type=x509;encoding=B:dGhpcyBjb3VsZCBiZSAKbXkgY2VydGlmaWNhdGUK\n")['key']

    card << Vpim::DirectoryInfo::Field.create('key', key, 'encoding' => :b64)

    assert_equal(key, card['key'])

    #p card.to_s
  end

  def test_values

    # date
    assert_equal([2002, 4, 22],       Vpim.decode_date(" 20020422  "))
    assert_equal([2002, 4, 22],       Vpim.decode_date(" 2002-04-22  "))
    assert_equal([2002, 4, 22],       Vpim.decode_date(" 2002-04-22 \n"))

    assert_equal([[2002, 4, 22]],
      Vpim.decode_date_list(" 2002-04-22 "))

    assert_equal([[2002, 4, 22],[2002, 4, 22]],
      Vpim.decode_date_list(" 2002-04-22, 2002-04-22,"))

    assert_equal([[2002, 4, 22],[2002, 4, 22]],
      Vpim.decode_date_list(" 2002-04-22,,, ,   ,2002-04-22, , \n"))

    assert_equal([],
      Vpim.decode_date_list("  ,           , "))

    # time
    assert_equal(
       [4, 53, 22, 0, nil],
       Vpim.decode_time(" 04:53:22 \n")
       )
    assert_equal(
       [4, 53, 22, 0.10, nil],
       Vpim.decode_time(" 04:53:22.10 \n")
       )
    assert_equal(
       [4, 53, 22, 0.10, "Z"],
       Vpim.decode_time(" 04:53:22.10Z \n")
       )
    assert_equal(
       [4, 53, 22, 0, "Z"],
       Vpim.decode_time(" 045322Z \n")
       )
    assert_equal(
       [4, 53, 22, 0, "+0530"],
       Vpim.decode_time(" 04:5322+0530 \n")
       )
    assert_equal(
       [4, 53, 22, 0.10, "Z"],
       Vpim.decode_time(" 045322.10Z \n")
       )

    # date-time
    assert_equal(
       [2002, 4, 22, 4, 53, 22, 0, nil],
       Vpim.decode_date_time("20020422T04:53:22 \n")
       )
    assert_equal(
       [2002, 4, 22, 4, 53, 22, 0.10, nil],
       Vpim.decode_date_time(" 2002-04-22T04:53:22.10 \n")
       )
    assert_equal(
       [2002, 4, 22, 4, 53, 22, 0.10, "Z"],
       Vpim.decode_date_time(" 20020422T04:53:22.10Z \n")
       )
    assert_equal(
       [2002, 4, 22, 4, 53, 22, 0, "Z"],
       Vpim.decode_date_time(" 20020422T045322Z \n")
       )
    assert_equal(
       [2002, 4, 22, 4, 53, 22, 0, "+0530"],
       Vpim.decode_date_time(" 20020422T04:5322+0530 \n")
       )
    assert_equal(
       [2002, 4, 22, 4, 53, 22, 0.10, "Z"],
       Vpim.decode_date_time(" 20020422T045322.10Z \n")
       )
    assert_equal(
       [2003, 3, 25, 3, 20, 35, 0, "Z"],
       Vpim.decode_date_time("20030325T032035Z")
       )

    # text
    assert_equal(
                        "aa,\n\n,\\,\\a;;b",
       Vpim.decode_text('aa,\\n\\n,\\\\\,\\\\a\;\;b')
       )
    assert_equal(
                         ['', "1\n2,3", "bbb", '', "zz", ''],
       Vpim.decode_text_list(',1\\n2\\,3,bbb,,zz,')
       )
  end

EX_ENCODE_1 =<<'EOF' 
BEGIN:VCARD 
VERSION:3.0
N:Roberts;Sam;;;
FN:Roberts Sam
EMAIL;type=HOME;type=pref:sroberts@uniserve.com
TEL;type=HOME:416 535 5341
ADR;type=HOME;type=pref:;;376 Westmoreland Ave.;Toronto;ON;M6H 3A6;Canada
NOTE:CATEGORIES: Amis/Famille 
BDAY;value=date:1970-07-14
END:VCARD
EOF

  def test_create_1
    card = Vpim::Vcard.create

    card << DirectoryInfo::Field.create('n', 'Roberts;Sam;;;')
    card << DirectoryInfo::Field.create('fn', 'Roberts Sam')
    card << DirectoryInfo::Field.create('email', 'sroberts@uniserve.com', 'type' => ['home', 'pref'])
    card << DirectoryInfo::Field.create('tel', '416 535 5341', 'type' => 'home')
    # TODO - allow the value to be an array, in which case it will be
    # concatentated with ';'
    card << DirectoryInfo::Field.create('adr', ';;376 Westmoreland Ave.;Toronto;ON;M6H 3A6;Canada', 'type' => ['home', 'pref'])
    # TODO - allow the date to be a Date, and for value to be set correctly
    card << DirectoryInfo::Field.create('bday', Date.new(1970, 7, 14), 'value' => 'date')

    # puts card.to_s
  end

EX_BDAYS = <<'EOF'
BEGIN:VCARD
BDAY;value=date:206-12-15
END:VCARD
BEGIN:VCARD
BDAY;value=date:2003-12-09
END:VCARD
BEGIN:VCARD
END:VCARD
EOF

  def test_birthday
    cards = Vpim::Vcard.decode(EX_BDAYS)

    expected = [
      Date.new(Time.now.year, 12, 15),
      Date.new(2003, 12, 9),
      nil
    ]

    expected.each_with_index do | d, i|
      #pp d
      #pp i
      #pp cards[i]
      #pp cards[i].birthday.to_s
      #pp cards[i].birthday.class
      assert_equal(d, cards[i].birthday)
    end

  end

EX_ATTACH=<<'---'
BEGIN:VCARD
VERSION:3.0
N:Middle Family;Ny_full
PHOTO:val\nue
PHOTO;encoding=8bit:val\nue
PHOTO;encoding=8bit:val\nue
PHOTO;encoding=8bit;type=atype:val\nue
PHOTO;value=binary;encoding=8bit:val\nue
PHOTO;value=binary;encoding=8bit:val\nue
PHOTO;value=binary;encoding=8bit;type=atype:val\nue
PHOTO;value=text;encoding=8bit:val\nue
PHOTO;value=text;encoding=8bit:val\nue
PHOTO;value=text;encoding=8bit;type=atype:val\nue
PHOTO;value=uri:my://
PHOTO;value=uri;type=atype:my://
END:VCARD
---
  def test_attach
    card = Vpim::Vcard.decode(EX_ATTACH).first
    card.lines # FIXME - assert values are as expected
  end

EX_21=<<'---'
BEGIN:VCARD
VERSION:2.1
X-EVOLUTION-FILE-AS:AAA Our Fax
FN:AAA Our Fax
N:AAA Our Fax
ADR;WORK;PREF:
LABEL;WORK;PREF:
TEL;WORK;FAX:925 833-7660
TEL;HOME;FAX:925 833-7660
TEL;VOICE:1
TEL;FAX:2
EMAIL;INTERNET:e@c
TITLE:
NOTE:
UID:pas-id-3F93E22900000001
END:VCARD
---
  def test_v21_modification
    card0 = Vpim::Vcard.decode(EX_21).first
    card1 = Vpim::Vcard::Maker.make2(card0) do |maker|
      maker.nickname = 'nickname'
    end
    card2 = Vpim::Vcard.decode(card1.encode).first

    assert_equal(card0.version, card1.version)
    assert_equal(card0.version, card2.version)
  end

  def test_v21_versioned_copy
    card0 = Vpim::Vcard.decode(EX_21).first
    card1 = Vpim::Vcard::Maker.make2(Vpim::DirectoryInfo.create([], 'VCARD')) do |maker|
      maker.copy card0
    end
    card2 = Vpim::Vcard.decode(card1.encode).first

    assert_equal(card0.version, card2.version)
  end

  def test_v21_strip_version
    card0 = Vpim::Vcard.decode(EX_21).first

    card0.delete card0.field('VERSION')
    card0.delete card0.field('TEL')
    card0.delete card0.field('TEL')
    card0.delete card0.field('TEL')
    card0.delete card0.field('TEL')

    assert_raises(ArgumentError) do
      card0.delete card0.field('END')
    end
    assert_raises(ArgumentError) do
      card0.delete card0.field('BEGIN')
    end

    card1 = Vpim::Vcard::Maker.make2(Vpim::DirectoryInfo.create([], 'VCARD')) do |maker|
      maker.copy card0
    end
    card2 = Vpim::Vcard.decode(card1.encode).first

    assert_equal(30,            card2.version)
    assert_equal(nil,           card2.field('TEL'))
  end


EX_21_CASE0=<<'---'
BEGIN:VCARD
VERSION:2.1
N:Middle Family;Ny_full
TEL;PREF;HOME;VOICE:0123456789
TEL;FAX:0123456789
TEL;CELL;VOICE:0123456789
TEL;HOME;VOICE:0123456789
TEL;WORK;VOICE:0123456789
EMAIL:email@email.com
EMAIL:work@work.com
URL:www.email.com
URL:www.work.com
LABEL;CHARSET=ISO-8859-1;ENCODING=QUOTED-PRINTABLE:Box 1234=0AWorkv=E4gen =
  2=0AWorkv=E4gen 1=0AUme=E5=0AV=E4sterbotten=0A12345=0AS
END:VCARD
---
  def test_v21_case0
    card = Vpim::Vcard.decode(EX_21_CASE0).first
    # pp card.field('LABEL').value_raw
    # pp card.field('LABEL').value
  end

  def test_modify_name
    card = Vcard.decode("begin:vcard\nend:vcard\n").first

    assert_raises(InvalidEncodingError) do
      card.name
    end

    assert_raises(Unencodeable) do
      Vcard::Maker.make2(card) {}
    end

    card.make do |m|
      m.name {}
    end

    assert_equal('', card.name.given)
    assert_equal('', card.name.fullname)

    assert_raises(TypeError) do
      card.name.given = 'given'
    end

    card.make do |m|
      m.name do |n|
        n.given = 'given'
      end
    end

    assert_equal('given', card.name.given)
    assert_equal('given', card.name.fullname)
    assert_equal(''     , card.name.family)

    card.make do |m|
      m.name do |n|
        n.family = n.given
        n.prefix = ' Ser '
        n.fullname = 'well given'
      end
    end

    assert_equal('given', card.name.given)
    assert_equal('given', card.name.family)
    assert_equal('Ser given given', card.name.formatted)
    assert_equal('well given', card.name.fullname)
  end

  def test_add_note
    note = "hi\' \  \"\",,;; \n \n field"

    card = Vpim::Vcard::Maker.make2 do |m|
      m.add_note(note)
      m.name {}
    end

    assert_equal(note, card.note)
  end

  def test_empty_tel
    cin = <<___
BEGIN:VCARD
TEL;HOME;FAX:
END:VCARD
___

    card = Vpim::Vcard.decode(cin).first
    assert_equal(card.telephone, nil)
    assert_equal(card.telephone('HOME'), nil)
    assert_equal([], card.telephones)
    
  end

  def test_slash_in_field_name
    cin = <<___
BEGIN:VCARD
X-messaging/xmpp-All:some@jabber.id
END:VCARD
___

    card = Vpim::Vcard.decode(cin).first
    assert_equal(card.value("X-messaging/xmpp-All"), "some@jabber.id")
    assert_equal(card["X-messaging/xmpp-All"], "some@jabber.id")
  end

  def test_url_decode
    cin=<<'---'
BEGIN:VCARD
URL:www.email.com
URL:www.work.com
END:VCARD
---
    card = Vpim::Vcard.decode(cin).first

    assert_equal("www.email.com", card.url.uri)
    assert_equal("www.email.com", card.url.uri.to_s)
    assert_equal("www.email.com", card.urls.first.uri)
    assert_equal("www.work.com", card.urls.last.uri)
  end

  def test_bday_decode
    cin=<<'---'
BEGIN:VCARD
BDAY:1970-07-14
END:VCARD
---
    card = Vpim::Vcard.decode(cin).first

    card.birthday

    assert_equal(Date.new(1970, 7, 14), card.birthday)
    assert_equal(1, card.values("bday").size)

    # Nobody should have multiple bdays, I hope, but its allowed syntactically,
    # so test it, along with some variant forms of BDAY
    cin=<<'---'
BEGIN:VCARD
BDAY:1970-07-14
BDAY:70-7-14
BDAY:1970-07-15T03:45:12
BDAY:1970-07-15T03:45:12Z
END:VCARD
---
    card = Vpim::Vcard.decode(cin).first

    assert_equal(Date.new(1970, 7, 14), card.birthday)
    assert_equal(4, card.values("bday").size)
    assert_equal(Date.new(1970, 7, 14), card.values("bday").first)
    assert_equal(Date.new(Time.now.year, 7, 14), card.values("bday")[1])
    assert_equal(DateTime.new(1970, 7, 15, 3, 45, 12).to_s, card.values("bday")[2].to_s)
    assert_equal(DateTime.new(1970, 7, 15, 3, 45, 12).to_s, card.values("bday").last.to_s)
  end

  def utf_name_test(c)

    begin
    card = Vpim::Vcard.decode(c).first
    assert_equal("name", card.name.family)
    rescue
      $!.message << " #{c.inspect}"
      raise
    end
  end

  def be(s)
    s.unpack('U*').pack('n*')
  end
  def le(s)
    s.unpack('U*').pack('v*')
  end

  def test_utf_heuristics
    bom = "\xEF\xBB\xBF"
    dat = "BEGIN:VCARD\nN:name\nEND:VCARD\n"
    utf_name_test(bom+dat)
    utf_name_test(bom+dat.downcase)
    utf_name_test(dat)
    utf_name_test(dat.downcase)

    utf_name_test(be(bom+dat))
    utf_name_test(be(bom+dat.downcase))
    utf_name_test(be(dat))
    utf_name_test(be(dat.downcase))

    utf_name_test(le(bom+dat))
    utf_name_test(le(bom+dat.downcase))
    utf_name_test(le(dat))
    utf_name_test(le(dat.downcase))
  end

  # Broken output from Highrise. Report to support@highrisehq.com
  def test_highrises_invalid_google_talk_field
    c = <<'__'
BEGIN:VCARD
VERSION:3.0
REV:20080409T095515Z
X-YAHOO;TYPE=HOME:yahoo.john
X-GOOGLE TALK;TYPE=WORK:gtalk.john
X-SAMETIME;TYPE=WORK:sametime.john
X-SKYPE;TYPE=WORK:skype.john
X-MSN;TYPE=WORK:msn.john
X-JABBER;TYPE=WORK:jabber.john
N:Doe;John;;;
ADR;TYPE=WORK:;;456 Grandview Building\, Wide Street;San Diego;CA;90204;
 United States
ADR;TYPE=HOME:;;123 Sweet Home\, Narrow Street;New York;NY;91102;United
  States
URL;TYPE=OTHER:http\://www.homepage.com
URL;TYPE=HOME:http\://www.home.com
URL;TYPE=WORK:http\://www.work.com
URL;TYPE=OTHER:http\://www.other.com
URL;TYPE=OTHER:http\://www.custom.com
ORG:John Doe & Partners Limited;;
TEL;TYPE=WORK:11111111
TEL;TYPE=CELL:22222222
TEL;TYPE=HOME:33333333
TEL;TYPE=OTHER:44444444
TEL;TYPE=FAX:55555555
TEL;TYPE=FAX:66666666
TEL;TYPE=PAGER:77777777
TEL;TYPE=OTHER:88888888
TEL;TYPE=OTHER:99999999
UID:cc548e11-569e-3bf5-a9aa-722de4571f4a
X-ICQ;TYPE=HOME:icq.john
EMAIL;TYPE=WORK,INTERNET:john.doe@work.com
EMAIL;TYPE=HOME,INTERNET:john.doe@home.com
EMAIL;TYPE=OTHER,INTERNET:john.doe@other.com
EMAIL;TYPE=OTHER,INTERNET:john.doe@custom.com
TITLE:Sales Manager
X-OTHER;TYPE=WORK:other.john
X-AIM;TYPE=WORK:aim.john
X-QQ;TYPE=WORK:qq.john
FN:John Doe
END:VCARD
__

    card = Vpim::Vcard.decode(c).first
    assert_equal("Doe", card.name.family)
    assert_equal("456 Grandview Building, Wide Street", card.address('work').street)
    assert_equal("123 Sweet Home, Narrow Street", card.address('home').street)
    assert_equal("John Doe & Partners Limited", card.org.first)
    assert_equal("gtalk.john", card.value("x-google talk"))
    assert_equal("http\\://www.homepage.com", card.url.uri)

  end

  def _test_gmail_vcard_export
    # GOOGLE BUG - Whitespace before the LABEL field values is a broken
    # line continuation.
    # GOOGLE BUG - vCards are being exported with embedded "=" in them, so
    # become unparseable.
    c = <<'__'
BEGIN:VCARD
VERSION:3.0
FN:Stepcase TestUser
N:TestUser;Stepcase;;;
EMAIL;TYPE=INTERNET:testuser@stepcase.com
X-GTALK:gtalk.step
X-AIM:aim.step
X-YAHOO:yahoo.step
X-MSN:msn.step
X-ICQ:icq.step
X-JABBER:jabber.step
TEL;TYPE=FAX:44444444
TEL;TYPE=PAGER:66666666
TEL;TYPE=HOME:22222222
TEL;TYPE=CELL:11111111
TEL;TYPE=FAX:55555555
TEL;TYPE=WORK:33333333
LABEL;TYPE=HOME;ENCODING=QUOTED-PRINTABLE:123 Home, Home Street=0D=0A=
Kowloon, N/A=0D=0A=
Hong Kong
LABEL;TYPE=HOME;ENCODING=QUOTED-PRINTABLE:321 Office, Work Road=0D=0A=
Tsuen Wan NT=0D=0A=
Hong Kong
TITLE:CTO
ORG:Stepcase.com
NOTE:Stepcase test user is a robot.
END:VCARD
__
    card = Vpim::Vcard.decode(c).first
    assert_equal("123 Home, Home Street\r\n Kowloon, N/A\r\n Hong Kong", card.value("label"))
  end

  def test_title
    title = "She Who Must Be Obeyed"
    card = Vpim::Vcard::Maker.make2 do |m|
      m.name do |n|
        n.given = "Hilda"
        n.family = "Rumpole"
      end
      m.title = title
    end
    assert_equal(title, card.title)
    card = Vpim::Vcard.decode(card.encode).first
    assert_equal(title, card.title)
  end

  def _test_org(*org)
    card = Vpim::Vcard::Maker.make2 do |m|
      m.name do |n|
        n.given = "Hilda"
        n.family = "Rumpole"
      end
      m.org = org
    end
    assert_equal(org, card.org)
    card = Vpim::Vcard.decode(card.encode).first
    assert_equal(org, card.org)
  end

  def test_org_single
    _test_org("Megamix Corp.")
  end

  def test_org_multiple
    _test_org("Megamix Corp.", "Marketing")
  end

end

