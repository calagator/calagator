require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/sources/edit.html.erb" do
  include SourcesHelper
  
  before do
    @source = mock_model(Source, :reimport => true)
    @source.stub!(:url).and_return("MyString")
    assigns[:source] = @source
  end

  it "should render edit form" do
    render "/sources/edit.html.erb"
    
    response.should have_tag("form[action=#{source_path(@source)}][method=post]") do
      with_tag('input#source_url[name=?]', "source[url]")
    end
  end
end


