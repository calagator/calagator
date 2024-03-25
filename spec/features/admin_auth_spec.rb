# frozen_string_literal: true

require "rails_helper"

describe "Administrative suite is hidden behind an http basic auth wall" do
  [
    "/admin",
    "/events/duplicates",
    "/venues/duplicates"
  ].each do |path|
    it "Users are not permitted in #{path}" do
      visit path
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
      expect(page).to have_content("Access denied")
    end

    it "Authenticated users are permitted in #{path}" do
      skip # Skipped until auth re-work
      page.driver.browser.basic_authorize Calagator.admin_username, Calagator.admin_password
      visit path
      expect([200, 304]).to include page.status_code
    end
  end
end
