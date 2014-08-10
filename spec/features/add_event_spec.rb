require "rails_helper"
require 'factory_girl'

feature "Event Creation" do
  scenario "User types venue name" do
    urban_airship = create(:venue, title: 'Urban Airship')

    visit "/events/new"
    fill_in "Event Name", with: 'Something'
    fill_in "Venue", with: "urban"

    expect(page).to have_text("Urban Airship")
  end
end
