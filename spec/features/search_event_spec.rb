# frozen_string_literal: true

require "rails_helper"

describe "search for events", js: true do
  before do
    create :event, title: "Ruby Future", start_time: today + 1.day
    create :event, title: "Python Past", start_time: today - 1.day
    create :event, title: "Ruby Part 2 Past", start_time: today - 2.days
    create :event, title: "Ruby Part 1 Past", start_time: today - 3.days
  end

  it "User searches for an event by name" do
    visit "/events/search?query=Ruby"

    # We're using send_keys here instead of fill_in in order to trigger the
    # correct events for JavaScript autocompletion.
    #
    # https://github.com/calagator/calagator/pull/448#issuecomment-129621567
    # This no longer works, unsure why
    # find_field("search_field").native.send_keys "Ruby\n"

    within("#current") do
      expect(page).to have_content "Viewing 1 current event"
      expect(page).to have_content "Ruby Future"
    end

    within("#past") do
      expect(page).to have_content "Viewing 2 past events"
      expect(page).to have_content "Ruby Part 2 Past"
      expect(page).to have_content "Ruby Part 1 Past"
    end
  end
end
