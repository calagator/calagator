# frozen_string_literal: true

require 'rails_helper'

describe 'browse venue by tag', js: true do
  before do
    create :venue, title: 'Giant Stadium', tag_list: 'old'
  end

  it 'User browses for venue by tag' do
    visit '/venues/tag/old'

    expect(page).to have_content 'Giant Stadium'
  end
end
