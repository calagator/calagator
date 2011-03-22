require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sources/show.html.erb" do
  include SourcesHelper
  
  before(:each) do
    @source = mock_model(Source)
    @source.stub!(:url).and_return("MyString")
    @source.stub!(:events).and_return([])

    assigns[:source] = @source
  end

  it "should render attributes in <p>" do
    render "/sources/show.html.erb"
    response.should have_text(/MyString/)
  end
end

