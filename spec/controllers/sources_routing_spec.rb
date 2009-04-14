require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SourcesController do
  describe "route generation" do

    it "should map { :controller => 'sources', :action => 'index' } to /sources" do
      route_for(:controller => "sources", :action => "index").should == "/sources"
    end
  
    it "should map { :controller => 'sources', :action => 'new' } to /sources/new" do
      route_for(:controller => "sources", :action => "new").should == "/sources/new"
    end
  
    it "should map { :controller => 'sources', :action => 'show', :id => 1 } to /sources/1" do
      route_for(:controller => "sources", :action => "show", :id => '1').should == "/sources/1"
    end
  
    it "should map { :controller => 'sources', :action => 'edit', :id => 1 } to /sources/1/edit" do
      route_for(:controller => "sources", :action => "edit", :id => '1').should == "/sources/1/edit"
    end
  
    it "should map { :controller => 'sources', :action => 'update', :id => 1} to /sources/1" do
      pending
      route_for(:controller => "sources", :action => "update", :id => '1').should == "/sources/1"
    end
  
    it "should map { :controller => 'sources', :action => 'destroy', :id => 1} to /sources/1" do
      pending
      route_for(:controller => "sources", :action => "destroy", :id => '1').should == "/sources/1"
    end
  end

  describe "route recognition" do

    it "should generate params { :controller => 'sources', action => 'index' } from GET /sources" do
      params_from(:get, "/sources").should == {:controller => "sources", :action => "index"}
    end
  
    it "should generate params { :controller => 'sources', action => 'new' } from GET /sources/new" do
      params_from(:get, "/sources/new").should == {:controller => "sources", :action => "new"}
    end
  
    it "should generate params { :controller => 'sources', action => 'create' } from POST /sources" do
      params_from(:post, "/sources").should == {:controller => "sources", :action => "create"}
    end
  
    it "should generate params { :controller => 'sources', action => 'show', id => '1' } from GET /sources/1" do
      params_from(:get, "/sources/1").should == {:controller => "sources", :action => "show", :id => "1"}
    end
  
    it "should generate params { :controller => 'sources', action => 'edit', id => '1' } from GET /sources/1;edit" do
      params_from(:get, "/sources/1/edit").should == {:controller => "sources", :action => "edit", :id => "1"}
    end
  
    it "should generate params { :controller => 'sources', action => 'update', id => '1' } from PUT /sources/1" do
      params_from(:put, "/sources/1").should == {:controller => "sources", :action => "update", :id => "1"}
    end
  
    it "should generate params { :controller => 'sources', action => 'destroy', id => '1' } from DELETE /sources/1" do
      params_from(:delete, "/sources/1").should == {:controller => "sources", :action => "destroy", :id => "1"}
    end
  end
end
