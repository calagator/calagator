# frozen_string_literal: true

require "spec_helper"

module Calagator
  describe Event::Browse do
    describe "when filtering by date range" do
      %i[start end].each do |date_kind|
        describe "for #{date_kind} date" do
          let(:start_date) { "2010-01-01" }
          let(:end_date) { "2010-04-01" }
          let(:date_field) { "#{date_kind}_date" }

          around do |example|
            Timecop.freeze(Time.zone.parse(start_date)) do
              example.run
            end
          end

          it "uses the default if not given the parameter" do
            browse = described_class.new(date: {})
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to be_empty
          end

          it "uses the default if given a malformed parameter" do
            browse = described_class.new(date: "omgkittens")
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "uses the default if given a missing parameter" do
            browse = described_class.new(date: {foo: "bar"})
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "uses the default if given an empty parameter" do
            browse = described_class.new(date: {date_kind => ""})
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "uses the default if given an invalid parameter" do
            browse = described_class.new(date: {date_kind => "omgkittens"})
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "uses the value if valid" do
            expected = Date.yesterday.strftime("%Y-%m-%d")
            browse = described_class.new(date: {date_kind => expected})
            expect(browse.send(date_field)).to eq expected
          end
        end
      end

      it "returns matching events" do
        # Given
        matching = [
          Event.create!(
            title: "matching1",
            start_time: Time.zone.parse("2010-01-16 00:00"),
            end_time: Time.zone.parse("2010-01-16 01:00")
          ),
          Event.create!(title: "matching2",
            start_time: Time.zone.parse("2010-01-16 23:00"),
            end_time: Time.zone.parse("2010-01-17 00:00"))
        ]

        # non_matching

        Event.create!(
          title: "nonmatchingbefore",
          start_time: Time.zone.parse("2010-01-15 23:00"),
          end_time: Time.zone.parse("2010-01-15 23:59")
        )
        Event.create!(
          title: "nonmatchingafter",
          start_time: Time.zone.parse("2010-01-17 00:01"),
          end_time: Time.zone.parse("2010-01-17 01:00")
        )

        # When
        browse = described_class.new(date: {start: "2010-01-16", end: "2010-01-16"})
        results = browse.events

        # Then
        expect(results).to eq matching
      end
    end

    describe "when filtering by time range" do
      let(:start_time) { "12:00 pm" }
      let(:end_time) { "05:00 pm" }

      let!(:before) do
        create(:event,
          title: "before",
          start_time: Time.zone.parse("10:00"),
          end_time: Time.zone.parse("14:00"))
      end

      let!(:after) do
        create(:event,
          title: "after",
          start_time: Time.zone.parse("14:00"),
          end_time: Time.zone.parse("18:00"))
      end

      let!(:within) do
        create(:event,
          title: "within",
          start_time: Time.zone.parse("13:00"),
          end_time: Time.zone.parse("14:00"))
      end

      context "before time" do
        subject do
          described_class.new(time: {end: end_time})
        end

        it "returns events with end_time before given end time" do
          expect(subject.events).to contain_exactly(before, within)
        end
      end

      context "after time" do
        subject do
          described_class.new(time: {start: start_time})
        end

        it "includes events with start_time after given start time" do
          expect(subject.events).to contain_exactly(after, within)
        end
      end

      context "within time range" do
        subject do
          described_class.new(time: {start: start_time, end: end_time})
        end

        it "includes events with start_time and end_time between given times" do
          expect(subject.events).to contain_exactly(within)
        end
      end
    end

    describe "when ordering" do
      it "defaults to order by start time" do
        event1 = create(:event, start_time: Time.zone.parse("3003-01-01"))
        event2 = create(:event, start_time: Time.zone.parse("3002-01-01"))
        event3 = create(:event, start_time: Time.zone.parse("3001-01-01"))

        browse = described_class.new
        expect(browse.events).to eq([event3, event2, event1])
      end

      it "can order by event name" do
        event1 = create(:event, title: "CU there")
        event2 = create(:event, title: "Be there")
        event3 = create(:event, title: "An event")

        browse = described_class.new(order: "name")
        expect(browse.events).to eq([event3, event2, event1])
      end

      it "can order by venue name" do
        event1 = create(:event, venue: create(:venue, title: "C venue"))
        event2 = create(:event, venue: create(:venue, title: "B venue"))
        event3 = create(:event, venue: create(:venue, title: "A venue"))

        browse = described_class.new(order: "venue")
        expect(browse.events).to eq([event3, event2, event1])
      end
    end

    describe "#default?" do
      it "is true when no params are supplied" do
        subject = described_class.new
        expect(subject).to be_default
      end

      it "is false when any params are supplied" do
        subject = described_class.new(order: "title")
        expect(subject).not_to be_default
      end
    end
  end
end
