require 'spec_helper'

describe VersionsController do
  render_views

  describe "history" do
    before :each do
      @versions_count_before = Version.count

      @venue = Venue.create!(:title => "Venue")

      @venue.title = "My Venue"
      @venue.save!

      @venue.destroy
    end

    after :each do
      @venue.versions.destroy_all
      @venue.destroy
    end

    describe "edit" do
      before :all do
        @venue = Venue.create!(:title => "myvenue")
        @event = Event.create!(:title => "myevent", :start_time => Time.now, :end_time => Time.now+1.hour, :venue => @venue)
        @event.title = "myevent v2"
        @event.save!
        @event.title = "myevent v3"
        @event.save!
        @event.destroy
        @event = @event.versions(true).last.reify
        @event.save!
      end

      after :all do
        @event.versions.destroy_all
        @event.destroy

        @venue.versions.destroy_all
        @venue.destroy
      end

      def refresh_with(version_id)
        get :edit, :id => version_id
        @result = controller.instance_variable_get(:@event)
      end

      it "should raise RecordNotFound if called with blank version" do
        lambda { refresh_with '' }.should raise_error(ActiveRecord::RecordNotFound)
      end

      it "should raise RecordNotFound if called with -1" do
        lambda { refresh_with '-1' }.should raise_error(ActiveRecord::RecordNotFound)
      end

      it "should render a create using intial content" do
        refresh_with @event.versions.first(:conditions => {:event => "create"}).id
        @result.title.should == "myevent"
      end

      it "should render an update using updated content" do
        refresh_with @event.versions.first(:conditions => {:event => "update"}).id
        @result.title.should == "myevent v2"
      end

      it "should render a destroy using final content" do
        refresh_with @event.versions.first(:conditions => {:event => "destroy"}).id
        @result.title.should == "myevent v3"
      end
    end
  end
end
