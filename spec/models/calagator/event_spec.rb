# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe Event, type: :model do
    describe 'in general'  do
      it 'is valid' do
        event = described_class.new(title: 'Event title', start_time: Time.zone.parse('2008.04.12'))
        expect(event).to be_valid
      end

      it 'adds a http:// prefix to urls without one' do
        event = described_class.new(title: 'Event title', start_time: Time.zone.parse('2008.04.12'), url: 'google.com')
        expect(event).to be_valid
      end

      it 'validates blacklisted words' do
        BlacklistValidator.any_instance.stub(patterns: [/\bcialis\b/, /\bviagra\b/])
        event = described_class.new(title: 'Foo bar cialis', start_time: Time.zone.parse('2008.04.12'), url: 'google.com')
        expect(event).not_to be_valid
      end

      it 'can be locked' do
        event = described_class.create(title: 'Event title', start_time: Time.zone.parse('2008.04.12'))
        event.lock_editing!
        expect(event.locked).to eq(true)
      end

      it 'can be unlocked' do
        event = described_class.create(title: 'Event title', start_time: Time.zone.parse('2008.04.12'), locked: true)
        event.unlock_editing!
        expect(event.locked).to eq(false)
      end

      it "can only be deleted when unlocked" do
        event = described_class.create(title: 'Event title', start_time: Time.zone.parse('2008.04.12'))

        event.lock_editing!
        expect(event.destroy).to eq(false)

        event.unlock_editing!
        expect(event.destroy).to be_truthy
      end
    end

    describe 'when checking time status' do
      it 'is old if event ended before today' do
        expect(build(:event, start_time: 2.days.ago, end_time: 1.day.ago)).to be_old
      end

      it 'is current if event is happening today' do
        expect(build(:event, start_time: 1.hour.from_now)).to be_current
      end

      it 'is ongoing if it began before today but ends today or later' do
        expect(build(:event, start_time: 1.day.ago, end_time: 1.day.from_now)).to be_ongoing
      end
    end

    describe 'dealing with tags' do
      before do
        @tags = 'some, tags'
        @event = described_class.new(title: 'Tagging Day', start_time: now)
      end

      it 'is taggable' do
        expect(@event.tag_list).to eq []
      end

      it 'adds tags without saving if it is a new record' do
        expect(@event).not_to receive :save
        expect(@event).to be_new_record
        @event.tag_list.add(@tags, parse: true)
        expect(@event.tag_list.to_s).to eq @tags
      end

      it 'uses tags with punctuation' do
        tags = ['.net', 'foo-bar']
        @event.tag_list.add(tags)
        @event.save

        @event.reload
        expect(@event.tags.map(&:name).sort).to eq tags.sort
      end

      it 'does not interpret numeric tags as IDs' do
        tag = ['123']
        @event.tag_list.add(tag)
        @event.save

        @event.reload
        expect(@event.tags.first.name).to eq '123'
      end

      it 'returns a collection of events for a given tag' do
        @event.tag_list.add(@tags, parse: true)
        @event.save
        expect(described_class.tagged_with('tags')).to eq [@event]
      end
    end

    describe 'when parsing' do
      before do
        @basic_hcal = read_sample('hcal_basic.xml')
        @basic_venue = mock_model(Venue, title: 'Argent Hotel, San Francisco, CA', full_address: '50 3rd St, San Francisco, CA 94103')
        @basic_event = described_class.new(
          title: 'Web 2.0 Conference',
          url: 'http://www.web2con.com/',
          start_time: 1.day.from_now,
          end_time: nil,
          venue: @basic_venue
        )
      end

      it 'parses an iCalendar into an Event' do
        url = 'http://foo.bar/'
        actual_ical = Event::IcalRenderer.render(@basic_event)
        stub_request(:get, url).to_return(body: actual_ical)

        events = Source::Parser.to_events(url: url)

        expect(events.size).to eq 1
        event = events.first
        expect(event.title).to eq @basic_event.title
        expect(event.url).to eq @basic_event.url
        expect(event.description).to be_blank

        expect(event.venue.title).to match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
      end

      it 'parses an iCalendar into an Event without a URL and generate it' do
        generated_url = 'http://foo.bar/'
        @basic_event.url = nil
        actual_ical = Event::IcalRenderer.render(@basic_event, url_helper: ->(_event) { generated_url })
        url = 'http://foo.bar/'
        stub_request(:get, url).to_return(body: actual_ical)

        events = Source::Parser.to_events(url: url)

        expect(events.size).to eq 1
        event = events.first
        expect(event.title).to eq @basic_event.title
        expect(event.url).to eq @basic_event.url
        expect(event.description).to match /Imported from: #{generated_url}/

        expect(event.venue.title).to match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
      end
    end

    describe 'when processing date' do
      before do
        @event = described_class.new(title: 'MyEvent')
      end

      it 'fails to validate if start time is nil' do
        @event.start_time = nil
        expect(@event).not_to be_valid
        expect(@event.errors[:start_time].size).to eq(1)
      end

      it 'fails to validate if start time is blank' do
        @event.start_time = ''
        expect(@event).not_to be_valid
        expect(@event.errors[:start_time].size).to eq(1)
      end

      it 'fails to validate if end_time is earlier than start time' do
        @event.start_time = now
        @event.end_time = @event.start_time - 2.hours
        expect(@event).to be_invalid
        expect(@event.errors[:end_time].size).to eq(1)
      end
    end

    describe 'when processing url' do
      before do
        @event = described_class.new(title: 'MyEvent', start_time: now)
      end

      let(:valid_urls) do
        [
          'hackoregon.org',
          'http://www.meetup.com/Hack_Oregon-Data/events/',
          'example.com',
          'sub.example.com/',
          'sub.domain.my-example.com',
          'example.com/?stuff=true',
          'example.com:5000/?stuff=true',
          'sub.domain.my-example.com/path/to/file/hello.html',
          'hello.museum',
          'http://example.com'
        ]
      end

      let(:invalid_urls) do
        [
          'hackoregon.org, http://www.meetup.com/Hack_Oregon-Data/events/',
          "hackoregon.org\nhttp://www.meetup.com/",
          'htttp://www.example.com'
        ]
      end

      it 'validates with valid urls (with scheme included or not)' do
        valid_urls.each do |valid_url|
          @event.url = valid_url
          expect(@event).to be_valid
        end
      end

      it 'fails to validate with invalid urls (with scheme included or not)' do
        invalid_urls.each do |invalid_url|
          @event.url = invalid_url
          expect(@event).to be_invalid
        end
      end
    end

    describe '#start_time=' do
      it 'clears with nil' do
        expect(described_class.new(start_time: nil).start_time).to be_nil
      end

      it 'sets from date String' do
        event = described_class.new(start_time: '2009-01-02')
        expect(event.start_time).to eq Time.zone.parse('2009-01-02')
      end

      it 'sets from date-time String' do
        event = described_class.new(start_time: '2009-01-02 03:45')
        expect(event.start_time).to eq Time.zone.parse('2009-01-02 03:45')
      end

      it 'sets from Date' do
        event = described_class.new(start_time: Date.parse('2009-02-01'))
        expect(event.start_time).to eq Time.zone.parse('2009-02-01')
      end

      it 'sets from DateTime' do
        event = described_class.new(start_time: Time.zone.parse('2009-01-01 05:30'))
        expect(event.start_time).to eq Time.zone.parse('2009-01-01 05:30')
      end

      it 'flags an invalid time and reset to nil' do
        event = described_class.new(start_time: '2010/1/1')
        event.start_time = '1/0'
        expect(event.start_time).to be_nil
        expect(event.errors[:start_time]).to be_present
      end
    end

    describe '#end_time=' do
      it 'clears with nil' do
        expect(described_class.new(end_time: nil).end_time).to be_nil
      end

      it 'sets from date String' do
        event = described_class.new(end_time: '2009-01-02')
        expect(event.end_time).to eq Time.zone.parse('2009-01-02')
      end

      it 'sets from date-time String' do
        event = described_class.new(end_time: '2009-01-02 03:45')
        expect(event.end_time).to eq Time.zone.parse('2009-01-02 03:45')
      end

      it 'sets from Date' do
        event = described_class.new(end_time: Date.parse('2009-02-01'))
        expect(event.end_time).to eq Time.zone.parse('2009-02-01')
      end

      it 'sets from DateTime' do
        event = described_class.new(end_time: Time.zone.parse('2009-01-01 05:30'))
        expect(event.end_time).to eq Time.zone.parse('2009-01-01 05:30')
      end

      it 'flags an invalid time' do
        event = described_class.new(end_time: '1/0')
        expect(event.errors[:end_time]).to be_present
      end
    end

    describe '#duration' do
      it 'returns the event length in seconds' do
        event = described_class.new(start_time: '2010-01-01', end_time: '2010-01-03')
        expect(event.duration).to eq(172_800)
      end

      it "returns zero if start and end times aren't present" do
        expect(described_class.new.duration).to eq(0)
      end
    end

    describe '.search_tag' do
      before do
        @c = create(:event, title: 'c', start_time: 3.minutes.ago, tag_list: %w[tag wtf])
        @b = create(:event, title: 'b', start_time: 2.minutes.ago, tag_list: %w[omg wtf])
        @a = create(:event, title: 'a', start_time: 1.minute.ago, tag_list: %w[tag omg])
      end

      it 'finds events with the given tag' do
        described_class.search_tag('tag').should == [@c, @a]
      end

      it 'accepts an order option' do
        described_class.search_tag('tag', order: 'name').should == [@a, @c]
      end
    end

    describe 'when finding by dates' do
      before do
        @today_midnight = today
        @yesterday = @today_midnight.yesterday
        @tomorrow = @today_midnight.tomorrow

        @this_venue = Venue.create!(title: 'This venue')

        @started_before_today_and_ends_after_today = described_class.create!(
          title: 'Event in progress',
          start_time: @yesterday,
          end_time: @tomorrow,
          venue_id: @this_venue.id
        )

        @started_midnight_and_continuing_after = described_class.create!(
          title: 'Midnight start',
          start_time: @today_midnight,
          end_time: @tomorrow,
          venue_id: @this_venue.id
        )

        @started_and_ended_yesterday = described_class.create!(
          title: 'Yesterday start',
          start_time: @yesterday,
          end_time: @yesterday.end_of_day,
          venue_id: @this_venue.id
        )

        @started_today_and_no_end_time = described_class.create!(
          title: 'nil end time',
          start_time: @today_midnight,
          end_time: nil,
          venue_id: @this_venue.id
        )

        @starts_and_ends_tomorrow = described_class.create!(
          title: 'starts and ends tomorrow',
          start_time: @tomorrow,
          end_time: @tomorrow.end_of_day,
          venue_id: @this_venue.id
        )

        @starts_after_tomorrow = described_class.create!(
          title: 'Starting after tomorrow',
          start_time: @tomorrow + 1.day,
          venue_id: @this_venue.id
        )

        @started_before_today_and_ends_at_midnight = described_class.create!(
          title: 'Midnight end',
          start_time: @yesterday,
          end_time: @today_midnight,
          venue_id: @this_venue.id
        )

        @future_events_for_this_venue = @this_venue.events.future
      end

      describe 'for future events' do
        before do
          @future_events = described_class.future
        end

        it 'includes events that started earlier today' do
          expect(@future_events).to include @started_midnight_and_continuing_after
        end

        it 'includes events with no end time that started today' do
          expect(@future_events).to include @started_today_and_no_end_time
        end

        it 'includes events that started before today and ended after today' do
          events = described_class.future
          expect(events).to include @started_before_today_and_ends_after_today
        end

        it 'includes events with no end time that started today' do
          expect(@future_events).to include @started_today_and_no_end_time
        end

        it 'does not include events that ended before today' do
          expect(@future_events).not_to include @started_and_ended_yesterday
        end
      end

      describe 'for future events with venue' do
        before do
          @another_venue = Venue.create!(title: 'Another venue')

          @future_event_another_venue = described_class.create!(
            title: 'Starting after tomorrow',
            start_time: @tomorrow + 1.day,
            venue_id: @another_venue.id
          )

          @future_event_no_venue = described_class.create!(
            title: 'Starting after tomorrow',
            start_time: @tomorrow + 1.day
          )
        end

        # TODO: Consider moving these examples elsewhere because they don't appear to relate to this scope. This comment applies to the examples from here...
        it 'includes events that started earlier today' do
          expect(@future_events_for_this_venue).to include @started_midnight_and_continuing_after
        end

        it 'includes events with no end time that started today' do
          expect(@future_events_for_this_venue).to include @started_today_and_no_end_time
        end

        it 'includes events that started before today and ended after today' do
          expect(@future_events_for_this_venue).to include @started_before_today_and_ends_after_today
        end

        it 'does not include events that ended before today' do
          expect(@future_events_for_this_venue).not_to include @started_and_ended_yesterday
        end
        # TODO: ...to here.

        it 'does not include events for another venue' do
          expect(@future_events_for_this_venue).not_to include @future_event_another_venue
        end

        it 'does not include events with no venue' do
          expect(@future_events_for_this_venue).not_to include @future_event_no_venue
        end
      end

      describe 'for date range' do
        it 'includes events that started earlier today' do
          events = described_class.within_dates(@today_midnight, @tomorrow)
          expect(events).to include @started_midnight_and_continuing_after
        end

        it 'includes events that started before today and end after today' do
          events = described_class.within_dates(@today_midnight, @tomorrow)
          expect(events).to include @started_before_today_and_ends_after_today
        end

        it 'does not include past events' do
          events = described_class.within_dates(@today_midnight, @tomorrow)
          expect(events).not_to include @started_and_ended_yesterday
        end

        it 'excludes events that start after the end of the range' do
          events = described_class.within_dates(@tomorrow, @tomorrow)
          expect(events).not_to include @started_today_and_no_end_time
        end
      end
    end

    describe 'when ordering' do
      describe 'with .ordered_by_ui_field' do
        it 'defaults to order by start time' do
          event1 = create(:event, start_time: Time.zone.parse('2003-01-01'))
          event2 = create(:event, start_time: Time.zone.parse('2002-01-01'))
          event3 = create(:event, start_time: Time.zone.parse('2001-01-01'))

          events = described_class.ordered_by_ui_field(nil)
          expect(events).to eq([event3, event2, event1])
        end

        it 'can order by event name' do
          event1 = create(:event, title: 'CU there')
          event2 = create(:event, title: 'Be there')
          event3 = create(:event, title: 'An event')

          events = described_class.ordered_by_ui_field('name')
          expect(events).to eq([event3, event2, event1])
        end

        it 'can order by venue name' do
          event1 = create(:event, venue: create(:venue, title: 'C venue'))
          event2 = create(:event, venue: create(:venue, title: 'B venue'))
          event3 = create(:event, venue: create(:venue, title: 'A venue'))

          events = described_class.ordered_by_ui_field('venue')
          expect(events).to eq([event3, event2, event1])
        end
      end
    end

    describe 'with finding duplicates' do
      before do
        @non_duplicate_event = create(:event)
        @duplicate_event = create(:duplicate_event)
        @events = [@non_duplicate_event, @duplicate_event]
      end

      it 'finds all events that have not been marked as duplicate' do
        non_duplicates = described_class.non_duplicates
        expect(non_duplicates).to include @non_duplicate_event
        expect(non_duplicates).not_to include @duplicate_event
      end

      it 'finds all events that have been marked as duplicate' do
        duplicates = described_class.marked_duplicates
        expect(duplicates).to include @duplicate_event
        expect(duplicates).not_to include @non_duplicate_event
      end
    end

    describe 'with finding duplicates (integration test)' do
      subject do
        create(:event)
      end

      before do
        # this event should always be omitted from the results
        past = create(:event, start_time: 1.week.ago)
      end

      it 'returns future events when provided na' do
        future = described_class.create!(title: subject.title, start_time: 1.day.from_now)
        events = described_class.find_duplicates_by_type('na')
        expect(events).to eq([nil] => [subject, future])
      end

      it 'finds duplicate title by title' do
        clone = described_class.create!(title: subject.title, start_time: subject.start_time)
        events = described_class.find_duplicates_by_type('title')
        expect(events).to eq([subject.title] => [subject, clone])
      end

      it 'finds duplicate title by any' do
        clone = described_class.create!(title: subject.title, start_time: subject.start_time + 1.minute)
        events = described_class.find_duplicates_by_type('title')
        expect(events).to eq([subject.title] => [subject, clone])
      end

      it 'does not find duplicate title by url' do
        clone = described_class.create!(title: subject.title, start_time: subject.start_time)
        events = described_class.find_duplicates_by_type('url')
        expect(events).to be_empty
      end

      it 'finds complete duplicates by all' do
        clone = described_class.create!(subject.attributes.merge(id: nil))
        events = described_class.find_duplicates_by_type('all')
        expect(events).to eq([nil] => [subject, clone])
      end

      it 'does not find incomplete duplicates by all' do
        clone = described_class.create!(subject.attributes.merge(title: 'SpaceCube', start_time: subject.start_time, id: nil))
        events = described_class.find_duplicates_by_type('all')
        expect(events).to be_empty
      end

      it 'finds duplicate for matching multiple fields' do
        clone = described_class.create!(title: subject.title, start_time: subject.start_time)
        events = described_class.find_duplicates_by_type('title,start_time')
        expect(events).to eq([subject.title, subject.start_time] => [subject, clone])
      end

      it 'does not find duplicates for mismatching multiple fields' do
        clone = described_class.create!(title: 'SpaceCube', start_time: subject.start_time)
        events = described_class.find_duplicates_by_type('title,start_time')
        expect(events).to be_empty
      end
    end

    describe 'when squashing duplicates (integration test)' do
      before do
        @event = create(:event, :with_venue)
        @venue = @event.venue
      end

      it "consolidates associations, merge tags, and update the venue's counter_cache" do
        @event.tag_list.add(%w[first second]) # primary event contains one duplicate tag, and one unique tag

        clone = described_class.create!(@event.attributes.merge(id: nil))
        clone.tag_list.replace %w[second third] # duplicate event also contains one duplicate tag, and one unique tag
        clone.save!
        clone.reload
        expect(clone).not_to be_duplicate
        expect(@venue.reload.events_count).to eq 2

        described_class.squash(@event, clone)
        expect(@event.tag_list.to_a.sort).to eq %w[first second third] # primary now contains all three tags
        expect(clone.duplicate_of).to eq @event
        expect(@venue.reload.events_count).to eq 1
      end
    end

    describe 'when checking for squashing' do
      before do
        @today  = today
        @primary = described_class.create!(title: 'primary',    start_time: @today)
        @duplicate1 = described_class.create!(title: '1st duplicate', start_time: @today, duplicate_of_id: @primary.id)
        @duplicate2 = described_class.create!(title: '2nd duplicate', start_time: @today, duplicate_of_id: @duplicate1.id)
        @orphan = described_class.create!(title: 'orphan',    start_time: @today, duplicate_of_id: 999_999)
      end

      it 'recognizes a primary' do
        expect(@primary).to be_a_primary
      end

      it 'recognizes a duplicate' do
        expect(@duplicate1).to be_a_duplicate
      end

      it 'does not think that a duplicate is a primary' do
        expect(@duplicate2).not_to be_a_primary
      end

      it 'does not think that a primary is a duplicate' do
        expect(@primary).not_to be_a_duplicate
      end

      it 'returns the originator of a duplicate' do
        expect(@duplicate1.originator).to eq @primary
      end

      it 'returns the originator of a secondary duplicate' do
        expect(@duplicate2.originator).to eq @primary
      end

      it 'returns a primary as its own originator' do
        expect(@primary.originator).to eq @primary
      end

      it 'returns a marked duplicate as originator if it is orphaned' do
        expect(@orphan.originator).to eq @orphan
      end
    end

    describe 'when versioning' do
      it 'has versions' do
        expect(described_class.new.versions).to eq []
      end

      it 'creates a new version after updating' do
        event = described_class.create!(title: 'Event title', start_time: Time.zone.parse('2008.04.12'))
        expect(event.versions.count).to eq 1

        event.title = 'New Title'
        event.save!
        expect(event.versions.count).to eq 2
      end
    end

    describe 'when converting to iCal' do
      def ical_roundtrip(events, opts = {})
        parsed_events = RiCal.parse_string(Event::IcalRenderer.render(events, opts)).first.events
        if events.is_a?(Event)
          parsed_events.first
        else
          parsed_events
        end
      end

      it 'produces parsable iCal output' do
        expect { ical_roundtrip(build(:event)) }.not_to raise_error
      end

      it 'represents an event without an end time as a 1-hour block' do
        event = build(:event, start_time: now, end_time: nil)
        expect(event.end_time).to be_blank

        rt = ical_roundtrip(event)
        expect(rt.dtend - rt.dtstart).to eq 1.hour
      end

      it 'sets the appropriate end time if one is given' do
        event = build(:event, start_time: now, end_time: now + 2.hours)

        rt = ical_roundtrip(event)
        expect(rt.dtend - rt.dtstart).to eq 2.hours
      end

      describe "when comparing Event's attributes to its iCalendar output" do
        let(:event) { build(:event, id: 123, created_at: now) }
        let(:ical) { ical_roundtrip(event) }

        { summary: :title,
          created: :created_at,
          last_modified: :updated_at,
          description: :description,
          url: :url,
          dtstart: :start_time,
          dtstamp: :created_at }.each do |ical_attribute, model_attribute|
          it "maps the Event's #{model_attribute} attribute to '#{ical_attribute}' in the iCalendar output" do
            model_value = event.send(model_attribute)
            ical_value = ical.send(ical_attribute)

            case model_value
            when ActiveSupport::TimeWithZone
              # Compare raw time because one is using local time zone, while other is using UTC time.
              expect(model_value.to_i).to eq ical_value.to_i
            else
              expect(model_value).to eq ical_value
            end
          end
        end
      end

      it 'calls the URL helper to generate a UID' do
        event = build(:event)
        expect(ical_roundtrip(event, url_helper: ->(_e) { "UID'D!" }).uid).to eq "UID'D!"
      end

      it 'strips HTML from the description' do
        event = create(:event, description: '<blink>OMFG HTML IS TEH AWESOME</blink>')
        expect(ical_roundtrip(event).description).not_to include '<blink>'
      end

      it 'includes tags in the description' do
        event = build(:event)
        event.tag_list.add('tags, folksonomy, categorization', parse: true)
        expect(ical_roundtrip(event).description).to include event.tag_list.to_s
      end

      it 'leaves URL blank if no URL is provided' do
        event = build(:event, url: nil)
        expect(ical_roundtrip(event).url).to be_nil
      end

      it 'has Source URL if URL helper is given)' do
        event = build(:event)
        expect(ical_roundtrip(event, url_helper: ->(_e) { 'FAKE' }).description).to match /FAKE/
      end

      it 'creates multi-day entries for multi-day events' do
        time = Time.zone.now
        event = build(:event, start_time: time, end_time: time + 4.days)
        parsed_event = ical_roundtrip(event)

        start_time = Date.current
        expect(parsed_event.dtstart).to eq start_time
        expect(parsed_event.dtend).to eq(start_time + 5.days)
      end

      describe 'sequence' do
        def event_to_ical(event)
          RiCal.parse_string(Event::IcalRenderer.render([event])).first.events.first
        end

        it 'sets an initial sequence on a new event' do
          event = create(:event)
          ical = event_to_ical(event)
          expect(ical.sequence).to eq 1
        end

        it 'increments the sequence if it is updated' do
          event = create(:event)
          event.update_attribute(:title, 'Update 1')
          ical = event_to_ical(event)
          expect(ical.sequence).to eq 2
        end

        # it "should offset the squence based the global Calagator.icalendar_sequence_offset" do
        # Calagator.should_receive(:icalendar_sequence_offset).and_return(41)
        # event = build(:event)
        # ical = event_to_ical(event)
        # ical.sequence.should eq 42
        # end
      end

      describe '- the headers' do
        before do
          @data = Event::IcalRenderer.render(build(:event))
        end

        it 'includes the calendar name' do
          expect(@data).to match /\sX-WR-CALNAME:#{Calagator.title}\s/
        end

        it 'includes the method' do
          expect(@data).to match /\sMETHOD:PUBLISH\s/
        end

        it 'includes the scale' do
          expect(@data).to match /\sCALSCALE:Gregorian\s/i
        end
      end
    end
  end
end
