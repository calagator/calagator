require 'spec_helper'

describe SiteController do
  describe "#omfg" do
    it "raises an error" do
      lambda { get :omfg }.should raise_exception(ArgumentError, "OMFG")
    end
  end

  describe "#hello" do
    it "renders 'hello' in plain text" do
      get :hello
      response.body.should == "hello"
    end
  end

  describe "#index" do
    it "should render requests for HTML successfully" do
      get :index
      response.should be_success
      response.should render_template :index
    end

    it "should redirect requests for non-HTML to events" do
      get :index, :format => "json"
      response.should redirect_to(events_path(:format => "json"))
    end
  end

  describe "about" do
    it "renders an html document" do
      get :about
      response.should be_success
      response.should render_template :about
    end
  end

  describe "opensearch" do
    it "renders an xml document" do
      get :opensearch, format: "xml"
      response.should be_success
      response.should render_template :opensearch
    end
  end

  describe "defunct" do
    it "renders an html document" do
      get :defunct
      response.should be_success
      response.should render_template :defunct
    end
  end
end
