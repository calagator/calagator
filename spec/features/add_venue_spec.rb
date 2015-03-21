require 'rails_helper'

feature 'Venue Creation' do
  let(:new_venue) { build(:venue) }

  scenario 'User adds a new venue' do

    visit '/'
    click_on 'Venues'
    click_on 'Add a venue'


    fill_in 'Venue Name', with: new_venue.title
    fill_in 'Full Address', with: new_venue.address
    fill_in 'Web Link', with: new_venue.url
    fill_in 'Email', with: new_venue.email
    fill_in 'Telephone', with: new_venue.telephone
    check("venue_wifi")
    fill_in 'Description', with: new_venue.description
    fill_in 'Access notes', with: 'Just knock?'

    click_on 'Create Venue'

    expect(page).to have_content 'Venue was successfully saved.'
    expect(page).to have_content new_venue.title
    expect(page).to have_content new_venue.address
    expect(page).to have_content new_venue.url
    expect(page).to have_content new_venue.email
    expect(page).to have_content new_venue.telephone
    expect(page).to have_content new_venue.description
    expect(page).to have_content 'Just knock?'
    expect(page).to have_content 'Public WiFi'
  end
end
