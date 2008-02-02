require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = Event.new
  end

  it "should be valid" do
    @event.should be_valid
  end
  
  it "should emit valid hCalendar" do
    expected_hcal = <<-EOF
<div class="vevent">
<a class="url" href="http://www.web2con.com/">http://www.web2con.com/</a>
<span class="summary">Web 2.0 Conference</span>: 
<abbr class="dtstart" title="2007-10-05">Friday, October 5, 2007</abbr>,
at the <span class="location">Argent Hotel, San Francisco, CA</span>
</div>
EOF
    @event.url = 'http://www.web2con.com/'
    @event.title = 'Web 2.0 Conference'
    @event.start_time = Time.parse('2007-10-05')
    @location = mock('Venue')
    @location.stub!(:title).and_return('Argent Hotel, San Francisco, CA')
    @event.stub!(:venue).and_return(@location)
    
    actual_hcal = @event.to_hcal
    actual_hcal.should == expected_hcal
  end
end
