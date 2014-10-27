#coding: UTF-8
require 'rails_helper'

feature 'Event Editing' do
  background do
    Timecop.travel('2014-10-09')
    create :event, title: 'Ruby Future', start_time: today
  end

  after do
    Timecop.return
  end

  scenario 'A user edits an existing event' do
    visit '/'

    within '#today' do
      click_on 'Ruby Future'
    end

    click_on 'edit'

    find_field('Event Name').value.should have_content 'Ruby Future'
    fill_in 'Event Name', with: 'Ruby ABCs'
    fill_in 'start_date', with: '2014-10-10'
    fill_in 'start_time', with: '06:00 PM'
    fill_in 'end_date', with: '2014-10-10'
    fill_in 'end_time', with: '07:00 PM'
    fill_in 'Website', with: 'www.rubynewbies.com'
    fill_in 'Description', with: 'An event for beginners'
    fill_in 'Tags', with: 'beginners,ruby'
    click_on 'Update Event'

    page.should have_content 'Event was successfully saved'
    page.should have_content 'Ruby ABCs'
    page.should have_content 'Friday, October 10, 2014 from 6–7pm'
    page.should have_content 'Website http://www.rubynewbies.com'
    page.should have_content 'Description An event for beginners'
    page.should have_content 'Tags beginners, ruby'

    click_on 'Calagator'
    within '#tomorrow' do
      page.should have_content 'Ruby ABCs'
    end
  end
end
