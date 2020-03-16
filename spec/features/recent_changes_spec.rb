# frozen_string_literal: true

require 'rails_helper'

describe 'Recent Changes', js: true do
  let(:event_title) { 'The Newest Event' }

  before do
    create :event, title: event_title, start_time: Time.zone.now
  end

  it 'A user browses recent changes' do
    visit '/changes'

    expect(page).to have_content 'CREATE'
    expect(page).to have_content event_title
  end

  it 'A user fetches the recent changes feed' do
    visit '/changes'
    click_on 'Changes feed'

    expect(page.body).to have_content 'CREATE'
    expect(page.body).to have_content event_title
  end
end
