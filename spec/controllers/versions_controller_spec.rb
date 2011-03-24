require File.dirname(__FILE__) + '/../spec_helper'

describe VersionsController do
  integrate_views

  describe "history" do
    before(:each) do
      Venue.destroy_all
      Event.destroy_all
      Version.destroy_all

      @venue = Venue.create!(:title => "Venue")

      @venue.title = "My Venue"
      @venue.save!

      @venue.destroy
    end

    describe "index" do
      before(:each) do
        get :index
        @versions = assigns[:versions].__value # Use #__value to extract data from DeferProxy
        @create_version  = @versions.find{|version| version.item_id == @venue.id && version.event == "create"}
        @update_version  = @versions.find{|version| version.item_id == @venue.id && version.event == "update"}
        @destroy_version = @versions.find{|version| version.item_id == @venue.id && version.event == "destroy"}
      end

      it "should have versions" do
        @versions.size.should == 3
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
    end

    describe "update" do
      before(:each) do
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
