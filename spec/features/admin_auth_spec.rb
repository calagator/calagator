require 'rails_helper'

feature 'Administrative suite is hidden behind an http basic auth wall' do
  scenario 'Users are not permitted in /admin' do
    visit '/admin'
    expect(page.status_code).to eq 401
  end

  scenario 'Authenticated users are permitted in /admin' do
    page.driver.basic_authorize SECRETS.admin_username, SECRETS.admin_password
    visit '/admin'
    expect(page.status_code).to eq 200
  end
end

