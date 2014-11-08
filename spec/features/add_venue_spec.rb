require 'rails_helper'

feature 'Venue Creation' do
  scenario 'User adds a new venue' do

    visit '/venues'
    click_on 'Add a venue'

    fill_in 'Venue Name', with: 'Empire State Building'
    fill_in 'Full Address', with: '350 5th Ave, New York, NY 10118, US'
    fill_in 'Web Link', with: 'EmpireStateBuildi.ng'
    fill_in 'Email', with: 'empire@state_building.com'
    fill_in 'Telephone', with: '(298)943-1337'
    check("venue_wifi")
    fill_in 'Description', with: 'Famous New York City Skyscraper'
    fill_in 'Access notes', with: 'Just knock I guess?'
    # fill_in 'Tags', with: ??

    click_on 'Create Venue'

    page.should have_content 'Venue was successfully saved.'
    page.should have_content 'Empire State Building'
    page.should have_content '350 5th Ave, New York, NY 10118, US'
    page.should have_content 'EmpireStateBuildi.ng'
    page.should have_content 'empire@state_building.com'
    page.should have_content '(298)943-1337'
    page.should have_content 'Public WiFi'
    page.should have_content 'Famous New York City Skyscraper'
    page.should have_content 'Just knock I guess?'
  end
end
