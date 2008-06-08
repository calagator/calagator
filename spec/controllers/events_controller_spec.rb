require File.dirname(__FILE__) + '/../spec_helper'

describe EventsController do
  integrate_views
  fixtures :events, :venues

  it "should find new duplicates and not old duplicates" do
    get 'duplicates'

    # New duplicates
    web3con = assigns[:grouped_events].select{|keys,values| keys.include?("Web 3.0 Conference")}
    web3con.should_not be_blank
    web3con.first.last.size.should == 2

    # Old duplicates
    web1con = assigns[:grouped_events].select{|keys,values| keys.include?("Web 1.0 Conference")}
    web1con.should be_blank
  end

  it "should redirect duplicate events to their master" do
    event_master = events(:calagator_codesprint)
    event_duplicate = events(:tomorrow)

    get 'show', :id => event_duplicate.id
    response.should_not be_redirect
    assigns(:event).id.should == event_duplicate.id

    event_duplicate.duplicate_of = event_master
    event_duplicate.save!

    get 'show', :id => event_duplicate.id
    response.should be_redirect
    response.should redirect_to(event_url(event_master.id))
  end
  
end

describe EventsController, "search" do
  
  before(:each) do
    @terms = "one two three four"
  end
  
  it "should receive a search string and run a Solr query" do
    pending "figuring out why solrquery is breaking with real params" do
      Event.stub!(:find_by_solr).and_return(mock('response', :results => nil))

      SolrQuery.should_receive(:new).with(@terms)
      post :search, :query => @terms
    end
  end

  
  it "should return an array of search results" do
    query = mock('query')
    response = mock('response')
    results = [mock_model(Event), mock_model(Event)]

#    SolrQuery.should_receive(:new).and_return(query)
    Event.should_receive(:find_by_solr).and_return(response)
    response.should_receive(:results).and_return(results)
    post :search, :query => @terms
  end

end