require 'rails_helper'

feature 'Venue Editing' do
  let(:venue) { create(:venue) }

  scenario 'A user edits an existing venue' do

    visit "/venues/#{venue.id}"
    click_on 'edit'

    find_field('Venue Name').value.should have_content "#{venue.title}"
    fill_in 'Venue Name', with: 'Space Needle'
    fill_in 'Street address', with: '400 Broad Street'
    fill_in 'City', with: 'Seattle'
    fill_in 'State', with: 'WA'
    fill_in 'Zip Code', with: '98109'
    fill_in 'Country', with: 'US'
    # fill_in 'Latitude*', with: ??
    # fill_in 'Longitude*', with: ??
    fill_in 'Web Link', with: 'SpaceNeed.le'
    fill_in 'Email', with: 'SpaceNeedle@hotmail.com'
    fill_in 'Telephone', with: '(298)587-7825'
    check('venue_wifi')
    fill_in 'Description', with: 'Most famous pointy building in Seattle.'
    fill_in 'Access notes', with: 'Just pay the exorbitant ticket price.'
    check('venue_closed')
    # check('venue_force_geocoding')

    click_on 'Update Venue'

    expect(page).to have_content 'Venue was successfully saved.'
    expect(page).to have_content 'Space Needle'
    expect(page).to have_content '400 Broad Street Seattle, WA 98109, US'
    expect(page).to have_content 'SpaceNeed.le'
    expect(page).to have_content 'SpaceNeedle@hotmail.com'
    expect(page).to have_content '(298)587-7825'
    expect(page).to have_content 'Public WiFi'
    expect(page).to have_content 'Most famous pointy building in Seattle.'
    expect(page).to have_content 'Just pay the exorbitant ticket price.'
    expect(page).to have_content 'This venue is no longer open for business.'
  end
end
