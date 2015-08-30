require 'spec_helper'

module Calagator
  describe Event::Browse do
    describe "when filtering by date range" do
      [:start, :end].each do |date_kind|
        describe "for #{date_kind} date" do
          let(:start_date) { "2010-01-01" }
          let(:end_date) { "2010-04-01" }
          let(:date_field) { "#{date_kind}_date" }

          around do |example|
            Timecop.freeze(Time.zone.parse(start_date)) do
              example.run
            end
          end

          it "should use the default if not given the parameter" do
            browse = Event::Browse.new(date: {})
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to be_empty
          end

          it "should use the default if given a malformed parameter" do
            browse = Event::Browse.new(date: "omgkittens")
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "should use the default if given a missing parameter" do
            browse = Event::Browse.new(date: { foo: "bar" })
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "should use the default if given an empty parameter" do
            browse = Event::Browse.new(date: { date_kind => "" })
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "should use the default if given an invalid parameter" do
            browse = Event::Browse.new(date: { date_kind => "omgkittens" })
            expect(browse.send(date_field)).to eq send(date_field)
            expect(browse.errors).to include(/invalid/)
          end

          it "should use the value if valid" do
            expected = Date.yesterday.to_s("%Y-%m-%d")
            browse = Event::Browse.new(date: { date_kind => expected })
            expect(browse.send(date_field)).to eq expected
          end
        end
      end

      it "should return matching events" do
        # Given
        matching = [
          Event.create!(
            :title => "matching1",
            :start_time => Time.zone.parse("2010-01-16 00:00"),
            :end_time => Time.zone.parse("2010-01-16 01:00")
          ),
          Event.create!(:title => "matching2",
            :start_time => Time.zone.parse("2010-01-16 23:00"),
            :end_time => Time.zone.parse("2010-01-17 00:00")
          ),
        ]

        non_matching = [
          Event.create!(
            :title => "nonmatchingbefore",
            :start_time => Time.zone.parse("2010-01-15 23:00"),
            :end_time => Time.zone.parse("2010-01-15 23:59")
          ),
          Event.create!(
            :title => "nonmatchingafter",
            :start_time => Time.zone.parse("2010-01-17 00:01"),
            :end_time => Time.zone.parse("2010-01-17 01:00")
          ),
        ]

        # When
        browse = Event::Browse.new(date: { start: "2010-01-16", end: "2010-01-16" })
        results = browse.events

        # Then
        expect(results).to eq matching
      end
    end

    describe "when filtering by time range" do
      let(:start_time) { "12:00 pm" }
      let(:end_time) { "05:00 pm" }

      let!(:before) do
        FactoryGirl.create(:event,
                           title: "before",
                           start_time: Time.zone.parse("10:00"),
                           end_time: Time.zone.parse("14:00"))
      end

      let!(:after) do
        FactoryGirl.create(:event,
                           title: "after",
                           start_time: Time.zone.parse("14:00"),
                           end_time: Time.zone.parse("18:00"))
      end

      let!(:within) do
        FactoryGirl.create(:event,
                           title: "within",
                           start_time: Time.zone.parse("13:00"),
                           end_time: Time.zone.parse("14:00"))
      end

      context "before time" do
        subject do
          Event::Browse.new(time: { end: end_time })
        end

        it "should return events with end_time before given end time" do
          expect(subject.events).to contain_exactly(before, within)
        end
      end

      context "after time" do
        subject do
          Event::Browse.new(time: { start: start_time })
        end

        it "should include events with start_time after given start time" do
          expect(subject.events).to contain_exactly(after, within)
        end
      end

      context "within time range" do
        subject do
          Event::Browse.new(time: { start: start_time, end: end_time })
        end

        it "should include events with start_time and end_time between given times" do
          expect(subject.events).to contain_exactly(within)
        end
      end
    end

    describe "when ordering" do
      it "defaults to order by start time" do
        event1 = FactoryGirl.create(:event, start_time: Time.zone.parse("3003-01-01"))
        event2 = FactoryGirl.create(:event, start_time: Time.zone.parse("3002-01-01"))
        event3 = FactoryGirl.create(:event, start_time: Time.zone.parse("3001-01-01"))

        browse = Event::Browse.new
        expect(browse.events).to eq([event3, event2, event1])
      end

      it "can order by event name" do
        event1 = FactoryGirl.create(:event, title: "CU there")
        event2 = FactoryGirl.create(:event, title: "Be there")
        event3 = FactoryGirl.create(:event, title: "An event")

        browse = Event::Browse.new(order: "name")
        expect(browse.events).to eq([event3, event2, event1])
      end

      it "can order by venue name" do
        event1 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "C venue"))
        event2 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "B venue"))
        event3 = FactoryGirl.create(:event, venue: FactoryGirl.create(:venue, title: "A venue"))

        browse = Event::Browse.new(order: "venue")
        expect(browse.events).to eq([event3, event2, event1])
      end
    end

    describe "#default?" do
      it "is true when no params are supplied" do
        subject = Event::Browse.new
        expect(subject.default?).to be_truthy
      end

      it "is false when any params are supplied" do
        subject = Event::Browse.new(order: "title")
        expect(subject.default?).to be_falsey
      end
    end
  end
end
