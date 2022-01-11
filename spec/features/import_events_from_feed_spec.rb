# frozen_string_literal: true

require 'rails_helper'

describe 'import events from a feed', js: true do
  before do
    Timecop.travel(Time.new(2010, 1, 1, 0, 0, 0, "-08:00"))
    stub_request(:get, 'http://even.ts/feed').to_return(body: read_sample('ical_multiple_calendars.ics'))
  end

  after do
    Timecop.return
  end

  it 'A user imports an events from a feed' do
    visit '/'
    click_on 'Import events'

    fill_in 'URL', with: 'http://even.ts/feed'
    click_on 'Import'

    expect(find('.flash')).to have_content <<~FLASH.strip
      Imported 3 entries:
      Coffee with Jason
      Coffee with Mike
      Coffee with Kim
    FLASH

    expect(page).to have_content 'Viewing 3 future events'

    expect(find('.event_table')).to have_content(/Coffee\swith\sJason\n.*\nCoffee\swith\sMike\n.*\nCoffee\swith\sKim/)
  end
end
