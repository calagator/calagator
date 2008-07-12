require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sources/index.html.erb" do
  include SourcesHelper
  
  before(:each) do
    source_98 = mock_model(Source)
    source_98.should_receive(:url).and_return("MyString")
    source_99 = mock_model(Source)
    source_99.should_receive(:url).and_return("MyString")

    assigns[:sources] = [source_98, source_99]
  end

  it "should render list of sources" do
    render "/sources/index.html.erb"
    response.should have_tag("tr>td", "MyString", 2)
  end
end

