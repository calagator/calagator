require 'rails_helper'

feature 'Event Creation' do
  scenario 'User begins typing a venue name', js: true do
    create(:venue, title: 'New Relic')
    create(:venue, title: 'Urban Airship')

    visit '/events/new'
    fill_in 'event_title', with: 'A Ruby meeting'
    fill_in 'venue_name',  with: 'urban'

    wait_for_ajax

    expect(page).to have_text('Urban Airship')
    expect(page).to have_no_text('New Relic')
  end
end
