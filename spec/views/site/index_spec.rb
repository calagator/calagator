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

    @tagcloud_items = [
      {:tag => Tag.create(:name => "foo"), :level => 1},
      {:tag => Tag.create(:name => "bar"), :level => 2},
      {:tag => Tag.create(:name => "baz"), :level => 3},
    ]

    assigns[:times_to_events_deferred] = lambda { @times_to_events }
    assigns[:tagcloud_items_deferred] = lambda { @tagcloud_items }
  end

  it "should render valid XHTML" do
    render "/site/index"
    response.should be_valid_xhtml_fragment

    response.should have_tag("#coming_events a[href=#{event_url(@codesprint)}]", @codesprint.title)
    response.should have_tag("#coming_events a[href=#{@codesprint.url}]")

    response.should have_tag('#tagcloud')
    response.should have_tag('#tagcloud a', 3)
    response.should have_tag('#tagcloud a[href="/events/search?tag=baz"][class="tagcloud_level_3"]')
  end

end

