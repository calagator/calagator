require 'rails_helper'

feature 'Venue Editing' do
  let(:venue) { create(:venue) }
  let(:new_venue) { build(:venue) }

  scenario 'A user edits an existing venue' do

    visit "/venues/#{venue.id}"
    click_on 'edit'

    venue_name = find_field('Venue Name').value
    expect(venue_name).to have_content "#{venue.title}"

    fill_in 'Venue Name', with: new_venue.title
    fill_in 'Street address', with: new_venue.street_address
    fill_in 'City', with: new_venue.locality
    fill_in 'State', with: new_venue.region
    fill_in 'Zip Code', with: new_venue.postal_code
    fill_in 'Country', with: new_venue.country
    # fill_in 'Latitude*', with: ??
    # fill_in 'Longitude*', with: ??
    fill_in 'Web Link', with: new_venue.url
    fill_in 'Email', with: new_venue.email
    fill_in 'Telephone', with: new_venue.telephone
    check('venue_wifi') if new_venue.wifi
    fill_in 'Description', with: new_venue.description
    fill_in 'Access notes', with: 'Just pay the ticket price.'
    check('venue_closed') if new_venue.closed
    # check('venue_force_geocoding')

    click_on 'Update Venue'

    expect(page).to have_content 'Venue was successfully saved.'
    expect(page).to have_content new_venue.title
    expect(page).to have_content new_venue.street_address
    expect(page).to have_content new_venue.locality
    expect(page).to have_content new_venue.region
    expect(page).to have_content new_venue.postal_code
    expect(page).to have_content new_venue.country
    expect(page).to have_content new_venue.url
    expect(page).to have_content new_venue.email
    expect(page).to have_content new_venue.telephone
    expect(page).to have_content new_venue.description
    expect(page).to have_content 'Public WiFi'
    expect(page).to have_content 'Just pay the ticket price.'
    expect(page).to have_content 'This venue is no longer open for business.' if new_venue.closed
  end
end
