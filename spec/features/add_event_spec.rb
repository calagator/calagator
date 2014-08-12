require 'rails_helper'

feature 'Event Creation' do
  scenario 'User begins typing a venue name', js: true do
    create :venue, title: 'New Relic'
    create :venue, title: 'Urban Airship'

    visit '/events/new'
    find_field('Venue').native.send_keys 'urban'

    expect(page).to have_text('Urban Airship')
    expect(page).to have_no_text('New Relic')
  end
end
