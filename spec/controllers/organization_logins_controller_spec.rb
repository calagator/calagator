require 'spec_helper'

describe OrganizationLoginsController, type: :controller do
  before do
    @organization = FactoryGirl.create(:organization)
  end

  describe "when I use the correct permalink" do
    subject { get :create, permalink: @organization.permalink }
    it "should set the session with a valid permalink" do
      subject
      expect(session[:organization_id]).to eq(@organization.id)
    end
    it "should redirect to the events page" do
      subject.should redirect_to(events_url)
    end
  end

  describe "when I use an invalid permalink" do
    subject { get :create, permalink: 'foobar' }
    it "should render 404" do
      subject
      expect(response.status).to eq(404)
    end
  end
end
