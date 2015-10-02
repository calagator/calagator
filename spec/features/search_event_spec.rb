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

    # We're using send_keys here instead of fill_in in order to trigger the
    # correct events for JavaScript autocompletion.
    #
    # https://github.com/calagator/calagator/pull/448#issuecomment-129621567
    find_field('Search Events').native.send_keys "Ruby\n"

    within('#current') do
      expect(page).to have_content 'Viewing 1 current event'
      expect(page).to have_content 'Ruby Future'
    end

    within('#past') do
      expect(page).to have_content 'Viewing 2 past events'
      expect(page).to have_content 'Ruby Part 2 Past'
      expect(page).to have_content 'Ruby Part 1 Past'
    end
  end
end
