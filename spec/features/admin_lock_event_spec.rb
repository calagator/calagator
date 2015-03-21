require 'rails_helper'

feature 'Event locking' do
  background do
    create :venue, title: 'Empire State Building'
    create :event, title: 'Ruby Newbies', start_time: Time.zone.now
    create :event, title: 'Ruby Privateers', start_time: Time.zone.now, locked: true

    page.driver.basic_authorize SECRETS.admin_username, SECRETS.admin_password

    visit '/admin'
    click_on 'Lock events'
  end

  scenario 'Admin locks an event to prevent it from being modified' do
    within 'tr', text: 'Ruby Newbies' do
      click_on 'Lock'
    end

    expect(page).to have_content('Locked event Ruby Newbies')
    click_on 'Ruby Newbies'

    expect(page).to have_content('This event is currently locked and cannot be edited.')
    expect(page).to_not have_selector('a', text: 'edit')
    expect(page).to_not have_selector('a', text: 'delete')
  end

  scenario 'Admin unlocks a locked event' do
    within 'tr', text: 'Ruby Privateers' do
      click_on 'Unlock'
    end

    expect(page).to have_content('Unlocked event Ruby Privateers')
    click_on 'Ruby Privateers'

    expect(page).to_not have_content('This event is currently locked and cannot be edited.')
    expect(page).to have_selector('a', text: 'edit')
    expect(page).to have_selector('a', text: 'delete')
  end
end

