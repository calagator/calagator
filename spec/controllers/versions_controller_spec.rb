require 'spec_helper'

describe VersionsController do
  describe "without versions" do
    it "should raise RecordNotFound if not given an id" do
      lambda do
        get :edit, :id => ''
      end.should raise_error ActiveRecord::RecordNotFound
    end

    it "should raise RecordNotFound if given invalid id" do
      lambda do
        get :edit, :id => '-1'
      end.should raise_error ActiveRecord::RecordNotFound
    end

    it "should raise RecordNotFound if given id that doesn't exist" do
      lambda do
        get :edit, :id => '1234'
      end.should raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "with versions" do
    before do
      @create_title = "myevent"
      @update_title = "myevent v2"
      @final_title = "myevent v3"

      @event = FactoryGirl.create(:event, :title => @create_title)

      @event.title = @update_title
      @event.save!

      @event.title = @final_title
      @event.save!

      @event.destroy
    end

    # Returns the versioned record's title for the event (e.g. :update).
    def title_for(event)
      version_id = @event.versions.where(event: event).pluck(:id).first

      get :edit, :id => version_id

      return assigns[:event].title
    end

    it "should render the initial content for a 'create'" do
      title_for(:create).should eq @create_title
    end

    it "should render the updated content for an 'update'" do
      title_for(:update).should eq @update_title
    end

    it "should render the final content for a 'destroy'" do
      title_for(:destroy).should eq @final_title
    end
  end
end
