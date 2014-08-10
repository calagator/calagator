require "rails_helper"
require 'factory_girl'

feature "Event Creation" do
  scenario "User enters venue name", js: true do
    new_relic     = create(:venue, title: 'New Relic')
    urban_airship = create(:venue, title: 'Urban Airship')

    visit "/events/new"
    fill_in 'event_title', with: 'A Ruby meeting'
    fill_in 'venue_name',  with: "urban"

    expect(page).to have_text("Urban Airship")
    expect(page).to have_no_text("New Relic")
  end
end
