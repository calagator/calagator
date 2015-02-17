require 'spec_helper'

module Calagator

describe Event::Cloner do
  describe "when cloning" do
    let :original do
      FactoryGirl.build(:event,
        :id => 42,
        :start_time => Time.zone.parse("2008-01-19 10:00:00"),
        :end_time => Time.zone.parse("2008-01-19 17:00:00"),
        :tag_list => "foo, bar, baz",
        :venue_details => "Details")
    end

    subject do
      Event::Cloner.clone(original)
    end

    it { should be_new_record }
    its(:id) { should be_nil }

    describe "#start_time" do
      it "should equal todays date with the same time" do
        start_time = Date.today + original.start_time.hour.hours
        subject.start_time.should == start_time
      end
    end

    describe "#end_time" do
      it "should equal todays date with the same time" do
        end_time = Date.today + original.end_time.hour.hours
        subject.end_time.should == end_time
      end
    end

    %w[title description url venue_id venue_details tag_list].each do |field|
      its(field) { should eq original.send(field) }
    end
  end
end

end
