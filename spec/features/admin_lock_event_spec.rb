require 'rails_helper'

feature 'Event locking' do
  background do
    create :venue, title: 'Empire State Building'
    create :event, title: 'Ruby Newbies'

    page.driver.basic_authorize SECRETS.admin_username, SECRETS.admin_password
  end

  scenario 'Admin signs in and locks an event to prevent it from being modified' do
    visit '/admin'
    click_on 'Lock events'

    within 'tr', text: 'Ruby Newbies' do
      click_on 'Lock'
    end

    expect(page).to have_content('Locked event Ruby Newbies')
    click_on 'Ruby Newbies'

    expect(page).to have_content('This event is currently locked and cannot be edited.')
    expect(page).to_not have_selector('a', text: 'edit')
    expect(page).to_not have_selector('a', text: 'delete')
  end
end

