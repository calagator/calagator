require 'spec_helper'

describe ActsAsTaggableOn::Tag, :type => :model do
  describe "handling machine tags" do
    before do
      @valid_machine_tag = ActsAsTaggableOn::Tag.new(:name => 'meetup:group=1234')
    end

    it "should return an empty hash when the tag is not a machine tag" do
      expect(ActsAsTaggableOn::Tag.new(:name => 'not a machine tag').machine_tag).to eq({})
    end

    it "should parse a machine tag into components" do
      expect(@valid_machine_tag.machine_tag[:namespace]).to eq 'meetup'
      expect(@valid_machine_tag.machine_tag[:predicate]).to eq 'group'
      expect(@valid_machine_tag.machine_tag[:value]).to eq '1234'
    end

    it "should generate a url for supported namespaces/predicates" do
      expect(@valid_machine_tag.machine_tag[:url]).to eq "http://www.meetup.com/1234"
    end

    it "should redirect to 'defunct' page with archive url as query param" do
      @event = FactoryGirl.create :event, tag_list: 'upcoming:event=1234'
      event_date = @event.start_time.strftime("%Y%m%d")
      expect(@event.tags.last.machine_tag[:url]).to eq "http://localhost:3000/defunct?url=https://web.archive.org/web/#{event_date}/http://upcoming.yahoo.com/event/1234"
    end

    it "should redirect correctly for venue tags also" do
      @venue = FactoryGirl.create :venue, tag_list: 'upcoming:venue=1234'
      venue_date = @venue.created_at.strftime("%Y%m%d")
      expect(@venue.tags.last.machine_tag[:url]).to eq "http://localhost:3000/defunct?url=https://web.archive.org/web/#{venue_date}/http://upcoming.yahoo.com/venue/1234"
    end
  end
end
