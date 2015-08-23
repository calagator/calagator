require 'rails_helper'

feature 'Admin lock events search' do
  background do
    create :venue, title: 'Empire State Building'
    create :event, title: 'Ruby Newbies', start_time: Time.zone.now
    create :event, title: 'Ruby Privateers', start_time: Time.zone.now, locked: true

    page.driver.basic_authorize Calagator.admin_username, Calagator.admin_password

    visit '/admin/events'
  end

  scenario 'only shows query matches' do
    fill_in 'admin_search_field', with: 'Privateers'

    click_on 'Search'

    expect(page).to_not have_content('Ruby Newbies')
    expect(page).to have_content('Ruby Privateers')
  end

  scenario 'only shows query matches after lock/unlock' do
    fill_in 'admin_search_field', with: 'Privateers'

    click_on 'Search'
    click_on 'Unlock'

    expect(page).to have_button('Lock')
    expect(page).to have_content('Ruby Privateers')
    expect(page).to_not have_content('Ruby Newbies')
  end
end
