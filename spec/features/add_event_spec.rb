require "rails_helper"
require 'factory_girl'

feature "Event Creation" do
  scenario "User enters venue name", js: true do
    new_relic = create(:venue, title: 'New Relic')
    urban_airship = create(:venue, title: 'Urban Airship')

    visit "/events/new"
    fill_in "Event Name", with: 'Something'
    fill_in "Venue", with: "urban"

    expect(page).to_not have_text("New Relic")
    expect(page).to have_text("Urban Airship")
  end
end
