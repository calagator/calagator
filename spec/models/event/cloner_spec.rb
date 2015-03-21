require 'spec_helper'

describe Event::Cloner do
  describe "when cloning" do
    let :original do
      FactoryGirl.build(:event,
        :id => 42,
        :start_time => Time.parse("2008-01-19 10:00 PST"),
        :end_time => Time.parse("2008-01-19 17:00 PST"),
        :tag_list => "foo, bar, baz",
        :venue_details => "Details")
    end

    subject do
      Event::Cloner.clone(original)
    end

    its(:new_record?) { should be_truthy }

    its(:id) { should be_nil }

    its(:start_time) { should eq today + original.start_time.hour.hours }

    its(:end_time)   { should eq today + original.end_time.hour.hours }

    its(:tag_list) { should eq original.tag_list }

    %w[title description url venue_id venue_details].each do |field|
      its(field) { should eq original[field] }
    end
  end
end
