require 'rails_helper'

feature 'Organization Editing' do
  let!(:organization) { create(:organization) }
  let!(:event) { create(:event, organization: organization) }
  let!(:new_organization) { build(:organization) }

  scenario 'A user edits an existing organization' do

    visit "/"
    click_on organization.title
    click_on 'edit'

    organization_name = find_field('Organization Name').value
    expect(organization_name).to have_content "#{organization.title}"

    fill_in 'Organization Name', with: new_organization.title
    fill_in 'Web Link', with: new_organization.url
    fill_in 'Email', with: new_organization.email
    fill_in 'Telephone', with: new_organization.telephone
    fill_in 'Description', with: new_organization.description

    click_on 'Update Organization'

    expect(page).to have_content 'Organization was successfully saved.'
    expect(page).to have_content new_organization.title
    expect(page).to have_content new_organization.url
    expect(page).to have_content new_organization.email
    expect(page).to have_content new_organization.telephone
    expect(page).to have_content new_organization.description
  end
end

feature 'Organization Deletion' do
  background do
    create :organization, title: 'Test Organization'
  end

  scenario 'A user deletes a organization' do
    visit '/'
    click_on 'Organizations'

    within '#newest' do
      click_on 'Test Organization'
    end

    click_on 'delete'

    expect(page).to have_content %("Test Organization" has been deleted)

    click_on "List all organizations"

    expect(page).to have_content "Sorry, there are no organizations"
  end
end
