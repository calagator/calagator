# frozen_string_literal: true

require 'rails_helper'

# Basic middleware integration test to ensure Rack::JSONP continues to do its job
describe 'JSONP API results' do
  it 'User requests events.json with a JSONP callback specified' do
    visit '/events.json?callback=myFunction'
    expect(page).to have_content %r{^(?:/\*\*/)?myFunction\(}
  end
end
