require 'rails_helper'

feature 'Organization Creation' do
  let(:new_organization) { build(:organization) }

  scenario 'User adds a new organization' do

    visit '/'
    click_on 'Organizations'
    click_on 'Add an organization'


    fill_in 'Organization Name', with: new_organization.title
    fill_in 'Web Link', with: new_organization.url
    fill_in 'Email', with: new_organization.email
    fill_in 'Telephone', with: new_organization.telephone
    fill_in 'Description', with: new_organization.description

    click_on 'Create Organization'

    expect(page).to have_content 'Organization was successfully saved.'
    expect(page).to have_content new_organization.title
    expect(page).to have_content new_organization.url
    expect(page).to have_content new_organization.email
    expect(page).to have_content new_organization.telephone
    expect(page).to have_content new_organization.description
  end
end
