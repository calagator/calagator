# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe Source::Parser, type: :model do
    around do |example|
      Timecop.freeze('2000-01-01') do
        example.run
      end
    end

    describe 'when reading content' do
      it 'reads from a normal URL' do
        stub_request(:get, 'http://a.real/~url').to_return(body: '42')
        expect(described_class.read_url('http://a.real/~url')).to eq '42'
      end

      it 'raises an error when unauthorized' do
        stub_request(:get, 'http://a.private/~url').to_return(status: [401, 'Forbidden'])
        expect do
          described_class.read_url('http://a.private/~url')
        end.to raise_error Source::Parser::HttpAuthenticationRequiredError
      end
    end

    describe 'when subclassing' do
      it 'demands that #to_events is implemented' do
        expect { described_class.new.to_events }.to raise_error NotImplementedError
      end
    end

    describe 'when parsing events' do
      before do
        Calagator.facebook_access_token = 'fake_access_token'
      end

      it 'has site-specific parsers first, then generics' do
        expect(described_class.parsers.to_a).to eq [
          Source::Parser::Facebook,
          Source::Parser::Hcal,
          Source::Parser::Ical
        ]
      end

      it "uses first successful parser's results" do
        events = [double]

        body = {
          name: 'event',
          start_time: '2010-01-01 12:00:00 UTC',
          end_time: '2010-01-01 13:00:00 UTC'
        }.to_json
        stub_request(:get, 'https://graph.facebook.com/omg?access_token=fake_access_token').to_return(body: body, headers: { content_type: 'application/json' })

        expect(described_class.to_events(url: 'http://www.facebook.com/events/omg')).to have(1).event
      end
    end

    describe 'checking duplicates when importing' do
      describe 'with two identical events' do
        before do
          @venue_size_before_import = Venue.count
          url = 'http://mysample.hcal/'
          @cal_source = Source.new(title: 'Calendar event feed', url: url)
          @cal_content = %(
      <div class="vevent">
        <abbr class="dtstart" title="20080714"></abbr>
        <abbr class="summary" title="Bastille Day"></abbr>
        <abbr class="location" title="Arc de Triomphe"></abbr>
      </div>
      <div class="vevent">
        <abbr class="dtstart" title="20080714"></abbr>
        <abbr class="summary" title="Bastille Day"></abbr>
        <abbr class="location" title="Arc de Triomphe"></abbr>
      </div>)
          stub_request(:get, url).to_return(body: @cal_content)
          @events = @cal_source.to_events
          @created_events = @cal_source.create_events!
        end

        it 'onlies parse one event' do
          expect(@events.size).to eq 1
        end

        it 'creates only one event' do
          expect(@created_events.size).to eq 1
        end

        it 'creates only one venue' do
          expect(Venue.count).to eq @venue_size_before_import + 1
        end
      end

      describe 'with an event' do
        it "retrieves an existing event if it's an exact duplicate" do
          url = 'http://mysample.hcal/'
          hcal_source = Source.new(title: 'Calendar event feed', url: url)
          stub_request(:get, url).to_return(body: read_sample('hcal_event_duplicates_fixture.xml'))

          event = hcal_source.to_events.first
          event.save!

          event2 = hcal_source.to_events.first
          expect(event2).not_to be_a_new_record
        end

        it 'an event with a orphaned exact duplicate should should remove duplicate marking' do
          orphan = Event.create!(title: 'orphan', start_time: Time.parse('July 14 2008').in_time_zone, duplicate_of_id: 7_142_008)
          cal_content = %(
        <div class="vevent">
        <abbr class="summary" title="orphan"></abbr>
        <abbr class="dtstart" title="20080714"></abbr>
        </div>
          )
          url = 'http://mysample.hcal/'
          stub_request(:get, url).to_return(body: cal_content)

          cal_source = Source.new(title: 'Calendar event feed', url: url)
          imported_event = cal_source.create_events!.first
          expect(imported_event).not_to be_marked_as_duplicate
        end
      end

      describe 'should create two events when importing two non-identical events' do
        # This behavior is tested under
        #  describe Source::Parser::Hcal, "with hCalendar events" do
        #  'it "should parse a page with multiple events" '
      end

      describe 'two identical events with different venues' do
        before do
          cal_content = %(
        <div class="vevent">
          <abbr class="dtstart" title="20080714"></abbr>
          <abbr class="summary" title="Bastille Day"></abbr>
          <abbr class="location" title="Arc de Triomphe"></abbr>
        </div>
        <div class="vevent">
          <abbr class="dtstart" title="20080714"></abbr>
          <abbr class="summary" title="Bastille Day"></abbr>
          <abbr class="location" title="Bastille"></abbr>
        </div>
          )
          url = 'http://mysample.hcal/'
          stub_request(:get, url).to_return(body: cal_content)

          cal_source = Source.new(title: 'Calendar event feed', url: url)
          @parsed_events = cal_source.to_events
          @created_events = cal_source.create_events!
        end

        it 'parses two events' do
          expect(@parsed_events.size).to eq 2
        end

        it 'creates two events' do
          expect(@created_events.size).to eq 2
        end

        it 'has different venues for the parsed events' do
          expect(@parsed_events[0].venue).not_to eq @parsed_events[1].venue
        end

        it 'has different venues for the created events' do
          expect(@created_events[0].venue).not_to eq @created_events[1].venue
        end
      end

      it 'uses an existing venue when importing an event whose venue matches a squashed duplicate' do
        new_source = Source.create!(title: 'Squashed?!', url: 'http://IcalEventWithSquashedVenue.com/')
        primary_venue = Venue.create!(title: 'Prime')
        squashed_venue = Venue.create!(
          title: 'Squashed Duplicate Venue',
          duplicate_of_id: primary_venue.id
        )

        cal_content = %(
      <div class="vevent">
        <abbr class="dtstart" title="20090117"></abbr>
        <abbr class="summary" title="Event with cloned venue"></abbr>
        <abbr class="location" title="Squashed Duplicate Venue"></abbr>
      </div>
        )

        url = 'http://mysample.hcal/'
        stub_request(:get, url).to_return(body: cal_content)

        source = Source.new(title: 'Event with squashed venue', url: url)

        event = source.to_events.first
        expect(event.venue.title).to eq 'Prime'
      end

      # We're no longer able to use the Meetup API, and none of the remaining importers have data with venue IDs
      xit 'uses an existing venue when importing an event with a matching machine tag that describes a venue' do
        venue = Venue.create!(title: 'Custom Urban Airship', tag_list: 'meetup:venue=774133')

        meetup_url = 'http://www.meetup.com/pdxpython/events/ldhnqyplbnb/'
        api_url = 'https://api.meetup.com/2/event/ldhnqyplbnb?key=foo&sign=true&fields=topics'

        stub_request(:get, api_url).to_return(body: read_sample('meetup.json'), headers: { content_type: 'application/json' })

        source = Source.new(title: 'Event with duplicate machine-tagged venue', url: meetup_url)
        event = source.to_events.first

        expect(event.venue).to eq venue
      end

      describe 'choosing parsers by matching URLs' do
        { 'Calagator::Source::Parser::Facebook' => 'http://facebook.com/event.php?eid=247619485255249' }.each do |parser_name, url|
          it "only invokes the #{parser_name} parser when given #{url}" do
            parser = parser_name.constantize
            expect_any_instance_of(parser).to receive(:to_events).and_return([Event.new])
            described_class.parsers.reject { |p| p == parser }.each do |other_parser|
              expect_any_instance_of(other_parser).not_to receive :to_events
            end

            stub_request(:get, url)
            Source.new(title: parser_name, url: url).to_events
          end
        end
      end
    end

    describe 'labels' do
      it 'has labels' do
        expect(described_class.labels).not_to be_blank
      end

      it 'has labels for each parser' do
        expect(described_class.labels.size).to eq described_class.parsers.size
      end

      it 'uses the label of the parser, as a string' do
        label = described_class.parsers.first.label.to_s
        expect(described_class.labels).to include label
      end

      it 'has sorted labels' do
        labels = described_class.labels
        sorted = labels.sort_by(&:downcase)

        expect(labels).to eq sorted
      end
    end
  end
end
