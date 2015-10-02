require 'rails_helper'

# Basic middleware integration test to ensure Rack::JSONP continues to do its job
feature "JSONP API results" do
  scenario "User requests events.json with a JSONP callback specified" do
    visit "/events.json?callback=myFunction"
    expect(page).to have_content /^(?:\/\*\*\/)?myFunction\(/
  end
end
