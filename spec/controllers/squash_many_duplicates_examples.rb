shared_examples "#squash_many_duplicates" do |model|
  before do
    @master = FactoryGirl.create(model, title: "master")
    @dup1 = FactoryGirl.create(model, title: "dup1")
    @dup2 = FactoryGirl.create(model, title: "dup2")
  end

  context "happy path" do
    before do
      post :squash_many_duplicates, master_id: @master.id, duplicate_id_1: @dup1.id, duplicate_id_2: @dup2.id
    end

    it "squashes the duplicates into the master" do
      @master.duplicate_ids.should =~ [@dup1.id, @dup2.id]
    end

    it "redirects to duplicates page for more duplicate squashing" do
      response.should redirect_to("/#{model}s/duplicates")
    end

    it "sets the flash success message" do
      flash[:success].should == %(Squashed duplicate #{model}s ["dup1", "dup2"] into master #{@master.id}.)
    end
  end

  context "with no master" do
    it "redirects with a failure message" do
      post :squash_many_duplicates, duplicate_id_1: @dup1.id, duplicate_id_2: @dup2.id
      flash[:failure].should == "A master #{model} must be selected."
      response.should redirect_to("/#{model}s/duplicates")
    end
  end

  context "with no duplicates" do
    it "redirects with a failure message" do
      post :squash_many_duplicates, master_id: @master.id
      flash[:failure].should == "At least one duplicate #{model} must be selected."
      response.should redirect_to("/#{model}s/duplicates")
    end
  end

  context "with duplicates containing master" do
    it "redirects with a failure message" do
      post :squash_many_duplicates, master_id: @master.id, duplicate_id_1: @master.id
      flash[:failure].should == "The master #{model} could not be squashed into itself."
      response.should redirect_to("/#{model}s/duplicates")
    end
  end
end
