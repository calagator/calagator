require File.dirname(__FILE__) + '/../../spec_helper'

describe "/site/index" do
  fixtures :events

  before(:each) do
    @codesprint         = events(:calagator_codesprint)
    @tomorrow           = events(:tomorrow)
    @day_after_tomorrow = events(:day_after_tomorrow)

    @times_to_events = {
      :today    => [@codesprint],
      :tomorrow => [@tomorrow],
      :later    => [@day_after_tomorrow],
    }

    assigns[:times_to_events_deferred] = lambda { @times_to_events }
  end

  it "should render valid XHTML" do
    render "/site/index"
    response.should be_valid_xhtml_fragment
  end

end

