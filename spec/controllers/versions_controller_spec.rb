require File.dirname(__FILE__) + '/../spec_helper'

describe VersionsController do
  integrate_views

  describe "history" do
    before :all do
      @versions_count_before = Version.count

      @venue = Venue.create!(:title => "Venue")

      @venue.title = "My Venue"
      @venue.save!

      @venue.destroy
    end

    after :all do
      @venue.versions.destroy_all
      @venue.destroy
    end

    describe "index" do
      before :each do
        get :index
        @versions = assigns[:versions].__value # Use #__value to extract data from DeferProxy
        @create_version  = @versions.find{|version| version.item_id == @venue.id && version.event == "create"}
        @update_version  = @versions.find{|version| version.item_id == @venue.id && version.event == "update"}
        @destroy_version = @versions.find{|version| version.item_id == @venue.id && version.event == "destroy"}
      end

      it "should have versions" do
        Version.count.should == @versions_count_before + 3
      end

      it "should include create for item" do
        version = @create_version
        version.should be_a_kind_of(Version)
        assert_select ".change_details a[name=#{version.id}]", /Create/
      end

      it "should include update for item" do
        version = @update_version
        version.should be_a_kind_of(Version)
        assert_select ".change_details a[name=#{version.id}]", /Update/
      end

      it "should include destroy for item" do
        version = @destroy_version
        version.should be_a_kind_of(Version)
        assert_select ".change_details a[name=#{version.id}]", /Destroy/
      end
    end

    describe "show" do
      # TODO
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

    describe "update" do
      before :each do
        @versions = Version.all
        @create_version  = @versions.find{|version| version.item_id == @venue.id && version.event == "create"}
        @update_version  = @versions.find{|version| version.item_id == @venue.id && version.event == "update"}
        @destroy_version = @versions.find{|version| version.item_id == @venue.id && version.event == "destroy"}
      end

      it "should rollback a create, by deleting current object" do
        Venue.should_receive(:find).and_return(@venue)
        @venue.should_receive(:destroy).and_return(true)

        put :update, :id => @create_version.id

        response.should redirect_to(versions_path)
      end

      it "should rollback an update" do
        lambda { Venue.find(@venue.id) }.should raise_error(ActiveRecord::RecordNotFound)

        put :update, :id => @update_version.id

        Venue.find(@venue.id).title.should == "Venue"
        response.should redirect_to(venue_path @venue)
      end

      it "should rollback a destroy" do
        lambda { Venue.find(@venue.id) }.should raise_error(ActiveRecord::RecordNotFound)

        put :update, :id => @destroy_version.id

        Venue.find(@venue.id).title.should == "My Venue"
        response.should redirect_to(venue_path @venue)
      end

      it "should fail on invalid version" do
        put :update, :id => "-1"

        flash[:failure].should_not be_blank
        response.should redirect_to(versions_path)
      end

      it "should fail on invalid rollback" do
        venue = stub_model(Venue)
        Venue.stub!(:find).and_return(venue)
        venue.should_receive(:save).and_return(false)

        put :update, :id => @destroy_version.id

        flash[:failure].should_not be_blank
        response.should redirect_to(versions_path)
      end
    end
  end
end
