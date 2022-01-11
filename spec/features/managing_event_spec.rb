# frozen_string_literal: true

require 'rails_helper'

describe 'Event Editing', js: true do
  before do
    Timecop.travel('2014-10-09')
    create :event, title: 'Ruby Future', start_time: Time.zone.now
    create :event, :with_multiple_tags, title: 'Tagged Event', start_time: Time.zone.now
  end

  after do
    Timecop.return
  end

  it 'A user edits an existing event' do
    visit '/'

    within '#today' do
      click_on 'Ruby Future'
    end

    click_on 'edit'
    expect(page).to have_content 'Editing: Ruby Future'

    expect(find_field('Event Name').value).to have_content 'Ruby Future'
    fill_in 'Event Name', with: 'Ruby ABCs'
    fill_in 'start_date', with: '2014-10-10'
    fill_in 'start_time', with: '06:00 PM'
    fill_in 'end_date', with: '2014-10-10'
    fill_in 'end_time', with: '07:00 PM'
    fill_in 'Website', with: 'www.rubynewbies.com'
    fill_in 'Description', with: 'An event for beginners'
    fill_in 'Tags', with: 'beginners,ruby'
    click_on 'Update Event'

    expect(page).to have_content 'Event was successfully saved'
    expect(page).to have_content 'Ruby ABCs'
    expect(page).to have_content 'Friday, October 10, 2014 from 6–7pm'
    expect(page).to have_content "Website\nhttp://www.rubynewbies.com"
    expect(page).to have_content "Description\nAn event for beginners"
    expect(page).to have_content "Tags\nbeginners, ruby"

    click_on 'Calagator'
    within '#whats_happening' do
      expect(page).to have_content 'Ruby ABCs'
    end
  end

  it 'A user edits an event with more than one tag' do
    visit '/'

    within '#today' do
      click_on 'Tagged Event'
    end

    click_on 'edit'

    fill_in 'Event Name', with: 'A Tagged Event'
    click_on 'Update Event'

    expect(page).to have_content 'tag1, tag2'

    within '.tags' do
      expect(page).to have_css 'a', count: 2
    end
  end
end

describe 'Event Cloning', js: true do
  before do
    Timecop.travel('2014-10-09')
    create :event, title: 'Ruby Event Part One', start_time: 4.days.from_now
  end

  after do
    Timecop.return
  end

  it 'A user clones an existing event' do
    visit '/'

    within '#next_two_weeks' do
      click_on 'Ruby Event Part One'
    end
    click_on 'clone'

    expect(find_field('Event Name').value).to have_content 'Ruby Event Part One'

    fill_in 'Event Name', with: 'Ruby Event Part Two'
    fill_in 'start_date', with: '2014-10-27'
    fill_in 'start_time', with: '06:00 PM'
    fill_in 'end_time', with: '11:00 PM'
    fill_in 'end_date', with: '2014-10-28'
    fill_in 'Website', with: 'www.rubynewbies.com'
    fill_in 'Description', with: 'An event for beginners'
    fill_in 'Tags', with: 'beginners,ruby'
    click_on 'Create Event'

    expect(page).to have_content 'Event was successfully saved'
    expect(page).to have_content 'Ruby Event Part Two'
    expect(page).to have_content 'Monday, October 27, 2014 at 6pm'
    expect(page).to have_content "Website\nhttp://www.rubynewbies.com"
    expect(page).to have_content "Description\nAn event for beginners"
    expect(page).to have_content "Tags\nbeginners, ruby"

    click_on 'Calagator'
    click_on 'View future events »'
    expect(page).to have_content 'Ruby Event Part Two'
  end
end

describe 'Event Deletion', js: true do
  before do
    create :event, title: 'Ruby and You', start_time: 1.day.from_now
  end

  it 'A user deletes an event' do
    visit '/'

    within '#tomorrow' do
      click_on 'Ruby and You'
    end

    accept_alert do
      click_on 'delete'
    end

    expect(page).to have_content '"Ruby and You" has been deleted'

    click_on 'Calagator'
    within '#tomorrow' do
      expect(page).to have_content '- No events -'
    end
  end
end
