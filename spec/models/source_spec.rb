require File.dirname(__FILE__) + '/../spec_helper'

describe Source do
  before(:each) do
    @source = Source.new
  end

  it "should parse hcal" do
    hcal_content = <<-HERE
<div class="vevent">
  <a href="http://www.cubespacepdx.com" class="url">
  <abbr title="20080119" class="dtstart">January 19th</abbr>,
  <abbr title="20080120" class="dtend"> 2008</abbr>
  <span class="summary">Calendar event</span>– at
  <span class="location">Cubespace, 622 SE Grand Ave. Portland, OR 97214</span></a>
  <div class="description">Check it out!</div>
</div>
    HERE
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/", :format_type => "hcal")
    SourceParser::Hcal.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events
    events.size.should == 1
    for key, value in {
      :title => "Calendar event",
      :description => "Check it out!",
      :start_time => Time.parse("2008-1-19"),
      :url => "http://www.cubespacepdx.com",
      :venue => nil, # TODO what should venue instance be?
    }
      events.first[key].should == value
    end
  end
  
  it "should parse a page with more than one hcal item in it" do
    hcal_content = <<-HERE
<div class="vevent">
  <a href="http://www.cubespacepdx.com" class="url">
  <abbr title="20080119" class="dtstart">January 19th</abbr>,
  <abbr title="20080120" class="dtend"> 2008</abbr>
  <span class="summary">Calendar event</span>– at
  <span class="location">Cubespace, 622 SE Grand Ave. Portland, OR 97214</span></a>
  <div class="description">Check it out!</div>
</div>
<div class="vevent">
  <a href="http://www.cubespacepdx.com" class="url">
  <abbr title="20080202" class="dtstart">February 2nd</abbr>,
  <abbr title="20080202" class="dtend"> 2008</abbr>
  <span class="summary">Calendar event</span>– at
  <span class="location">Cubespace, 622 SE Grand Ave. Portland, OR 97214</span></a>
  <div class="description">Check it out!</div>
</div>
    HERE
    hcal_source = Source.new(:title => "Calendar event feed", :url => "http://mysample.hcal/", :format_type => "hcal")
    SourceParser::Hcal.should_receive(:read_url).and_return(hcal_content)

    events = hcal_source.to_events
    events.size.should == 2
    first, second = *events
    first[:start_time ].should == Time.parse('2008-1-19')
    second[:start_time].should == Time.parse('2008-2-2')
  end


end
