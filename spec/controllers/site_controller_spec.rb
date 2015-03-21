require 'spec_helper'

describe SiteController, :type => :controller do
  describe "#omfg" do
    it "raises an error" do
      expect { get :omfg }.to raise_exception(ArgumentError, "OMFG")
    end
  end

  describe "#hello" do
    it "renders 'hello' in plain text" do
      get :hello
      expect(response.body).to eq("hello")
    end
  end

  describe "#index" do
    it "should render requests for HTML successfully" do
      get :index
      expect(response).to be_success
      expect(response).to render_template :index
    end

    it "should redirect requests for non-HTML to events" do
      get :index, :format => "json"
      expect(response).to redirect_to(events_path(:format => "json"))
    end
  end

  describe "about" do
    it "renders an html document" do
      get :about
      expect(response).to be_success
      expect(response).to render_template :about
    end
  end

  describe "opensearch" do
    it "renders an xml document" do
      get :opensearch, format: "xml"
      expect(response).to be_success
      expect(response).to render_template :opensearch
    end
  end

  describe "defunct" do
    it "renders an html document" do
      get :defunct
      expect(response).to be_success
      expect(response).to render_template :defunct
    end
  end
end
