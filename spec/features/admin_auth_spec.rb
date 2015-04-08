require 'rails_helper'

feature 'Administrative suite is hidden behind an http basic auth wall' do
  [
    '/admin',
    '/events/duplicates',
    '/venues/duplicates'
  ].each do |path|
    scenario "Users are not permitted in #{path}" do
      page.driver.basic_authorize 'nope', 'nada'
      visit path
      expect(page.status_code).to eq 401
    end

    scenario "Authenticated users are permitted in #{path}" do
      page.driver.basic_authorize Calagator.admin_username, Calagator.admin_password
      visit path
	  expect([200, 304]).to include page.status_code
    end
  end
end

