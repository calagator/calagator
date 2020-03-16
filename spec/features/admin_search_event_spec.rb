# frozen_string_literal: true

require 'rails_helper'

describe 'Admin lock events search' do
  before do
    create :venue, title: 'Empire State Building'
    create :event, title: 'Ruby Newbies', start_time: Time.zone.now
    create :event, title: 'Ruby Privateers', start_time: Time.zone.now, locked: true

    page.driver.browser.basic_authorize Calagator.admin_username, Calagator.admin_password

    visit '/admin/events'
  end

  it 'only shows query matches' do
    fill_in 'admin_search_field', with: 'Privateers'

    click_on 'Search'

    expect(page).not_to have_content('Ruby Newbies')
    expect(page).to have_content('Ruby Privateers')
  end

  it 'only shows query matches after lock/unlock' do
    fill_in 'admin_search_field', with: 'Privateers'

    click_on 'Search'
    click_on 'Unlock'

    expect(page).to have_button('Lock')
    expect(page).to have_content('Ruby Privateers')
    expect(page).not_to have_content('Ruby Newbies')
  end
end
