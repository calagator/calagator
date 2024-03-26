# frozen_string_literal: true

require "rails_helper"

describe "Venue Editing", js: true do
  let!(:venue) { create(:venue) }
  let!(:event) { create(:event, venue: venue, start_time: Time.now.in_time_zone.end_of_day - 1.hour) }
  let!(:new_venue) { build(:venue) }
  let!(:venue_with_tags) { create(:venue, :with_multiple_tags) }

  it "A user edits an existing venue" do
    visit "/"
    click_on venue.title
    click_on "edit"

    venue_name = find_field("Venue Name").value
    expect(venue_name).to have_content venue.title.to_s

    fill_in "Venue Name", with: new_venue.title
    fill_in "Street address", with: new_venue.street_address
    fill_in "City", with: new_venue.locality
    fill_in "State", with: new_venue.region
    fill_in "Zip Code", with: new_venue.postal_code
    fill_in "Country", with: new_venue.country
    fill_in "Web Link", with: new_venue.url
    fill_in "Email", with: new_venue.email
    fill_in "Telephone", with: new_venue.telephone
    check("venue_wifi") if new_venue.wifi
    fill_in "Description", with: new_venue.description
    fill_in "Access notes", with: "Just pay the ticket price."
    check("venue_closed") if new_venue.closed

    click_on "Update Venue"

    expect(page).to have_content "Venue was successfully saved."
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
    expect(page).to have_content "Public WiFi"
    expect(page).to have_content "Just pay the ticket price."
    if new_venue.closed
      expect(page).to have_content "This venue is no longer open for business."
    end
  end

  it "A user edits a venue with more than one tag" do
    visit "/"

    click_on "Venues"

    within "#newest" do
      click_on venue_with_tags.title
    end

    click_on "edit"

    fill_in "Venue Name", with: "A Tagged Venue"
    click_on "Update Venue"

    expect(page).to have_content "tag1, tag2"

    within ".tags" do
      expect(page).to have_css "a", count: 2
    end
  end
end

describe "Venue Deletion", js: true do
  before do
    create :venue, title: "Test Venue"
  end

  it "A user deletes a venue" do
    visit "/"
    click_on "Venues"

    within "#newest" do
      click_on "Test Venue"
    end

    accept_alert do
      click_on "delete"
    end

    expect(page).to have_content %("Test Venue" has been deleted)

    click_on "List all venues"

    expect(page).to have_content "Sorry, there are no venues"
  end
end
