require 'rails_helper'

feature 'browse venue by tag' do
  background do
    create :venue, title: 'Giant Stadium', tag_list: 'old'
  end

  scenario 'User browses for venue by tag' do
    visit '/venues/tag/old'

    expect(page).to have_content 'Giant Stadium'
  end

end
