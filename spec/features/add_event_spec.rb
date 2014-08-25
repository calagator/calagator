require 'rails_helper'

feature 'Event Creation', js: true do

  scenario 'User adds an event at an existing venue' do
    create :venue, title: 'Empire State Building'

    visit '/'
    click_on 'Add an event'

    fill_in 'Event Name', with: 'Ruby Newbies'
    find_field('Venue').native.send_keys 'Empire State'
    find('a', text: 'Empire State Building').click # click_on is preferable, but didn't work with jquery UI autocomplete

    fill_in 'start_date', with: '2014-08-05'
    fill_in 'start_time', with: '06:00 PM'
    fill_in 'end_time', with: '11:00 PM'
    fill_in 'end_date', with: '2014-08-06'
    fill_in 'Website', with: 'www.rubynewbies.com'
    fill_in 'Description', with: 'An event for beginners'
    fill_in 'Venue details', with: 'On the third floor'
    fill_in 'Tags', with: 'beginners,ruby'

    click_on 'Create Event'

    page.should have_content 'Event was successfully saved'
    page.should have_content 'Ruby Newbies'
    page.should have_content 'Empire State Building'
    page.should have_content 'Tuesday, August 5, 2014 at 6pm through Wednesday, August 6, 2014 at 11pm'
    page.should have_content 'Website http://www.rubynewbies.com'
    page.should have_content 'Description An event for beginners'
    page.should have_content 'On the third floor'
    page.should have_content 'Tags beginners, ruby'
  end

  scenario 'User begins typing a venue name' do
    create :venue, title: 'New Relic'
    create :venue, title: 'Urban Airship'

    visit '/events/new'
    find_field('Venue').native.send_keys 'urban'

    expect(page).to have_text('Urban Airship')
    expect(page).to have_no_text('New Relic')
  end
end
