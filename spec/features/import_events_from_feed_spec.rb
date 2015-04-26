require 'rails_helper'

feature 'import events from a feed' do
  background do
    Timecop.travel('2010-01-01')
    stub_request(:get, 'http://even.ts/feed').to_return(body: read_sample('ical_multiple_calendars.ics'))
  end

  after do
    Timecop.return
  end

  scenario 'A user imports an events from a feed' do
    visit '/'
    click_on 'Import events'

    fill_in 'URL', with: 'http://even.ts/feed'
    click_on 'Import'

    expect(find(".flash")).to have_content %(
      Imported 3 entries:

      Coffee with Jason
      Coffee with Mike
      Coffee with Kim
    )

    expect(page).to have_content 'Viewing 3 future events'

    expect(find(".event_table")).to have_content %(
      Thursday Apr 8

      Coffee with Jason
      7–8am

      Coffee with Mike
      7–8am

      Coffee with Kim
      7–8am
    )
  end
end
