require File.dirname(__FILE__) + '/../spec_helper'

describe Event do
  before(:each) do
    @event = Event.new
    @hcal = <<-EOF
<div class="vevent">
<a class="url" href="http://www.web2con.com/">http://www.web2con.com/</a>
<span class="summary">Web 2.0 Conference</span>: 
<abbr class="dtstart" title="2007-10-05">Friday, October 5, 2007</abbr>,
at the <span class="location">Argent Hotel, San Francisco, CA</span>
</div>
EOF
    
  end

  it "should be valid" do
    @event.should be_valid
  end
  
  it "should parse an abstract_event into an instance of Event" do
    Event.should_receive(:new).and_return(event = mock_model(Event, :title= => true, :description= => true, :start_time= => true, 
        :url= => true, :venue_id= => true))
    abstract_event = SourceParser::AbstractEvent.new('title', 'description', 'start_time', 'url')

    Event.from_abstract_event(abstract_event).should == event
  end

  it "should emit valid hCalendar" do
    @event.url = 'http://www.web2con.com/'
    @event.title = 'Web 2.0 Conference'
    @event.start_time = Time.parse('2007-10-05')
    @event.venue = mock_model(Venue, :title => 'Argent Hotel, San Francisco, CA')
    
    actual_hcal = @event.to_hcal
    actual_hcal.should == @hcal
  end
  
end
