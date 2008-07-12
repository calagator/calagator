require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sources/new.html.erb" do
  include SourcesHelper
  
  before(:each) do
    @source = mock_model(Source, :reimport => false, :url => '')
    @source.stub!(:new_record?).and_return(true)
    @source.stub!(:url).and_return("MyString")
    assigns[:source] = @source
  end

  it "should render valid XHTML" do
    render "/sources/new"
    response.should be_valid_xhtml_fragment
  end

  it "should render new form" do
    render "/sources/new.html.erb"
    
    response.should have_tag("form[action=?][method=post]", import_sources_path) do
      with_tag("input#source_url[name=?]", "source[url]")
    end
  end
end


