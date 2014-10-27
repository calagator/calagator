require 'rails_helper'

feature 'search for events' do
  background do
    create :event, title: 'Ruby Future', start_time: today + 1.day
    create :event, title: 'Python Past', start_time: today - 1.day
    create :event, title: 'Ruby Part 2 Past', start_time: today - 2.day
    create :event, title: 'Ruby Part 1 Past', start_time: today - 3.day
  end

  scenario 'User searches for an event by name' do
    visit '/'

    find_field('Search Events').native.send_keys "Ruby\n"

    within('#current') do
      page.should have_content 'Viewing 1 current event'
      page.should have_content 'Ruby Future'
    end

    within('#past') do
      page.should have_content 'Viewing 2 past events'
      page.should have_content 'Ruby Part 2 Past'
      page.should have_content 'Ruby Part 1 Past'
    end
  end
end
