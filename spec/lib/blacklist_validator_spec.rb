require "active_model"
require "blacklist_validator"

describe BlacklistValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Validations
      validates :title, blacklist: true
      attr_accessor :title
    end
  end

  subject { klass.new }

  describe "with default blacklist" do
    it "should be valid when clean" do
      subject.title = "Title"
      subject.should be_valid
    end

    it "should not be valid when it features blacklisted word" do
      subject.title = "Foo bar cialis"
      subject.should_not be_valid
    end
  end

  describe "with custom blacklist" do
    before do
      klass.validates :title, blacklist: { patterns: [/Kltpzyxm/i] }
    end

    it "should be valid when clean" do
      subject.title = "Title"
      subject.should be_valid
    end

    it "should not be valid when it features custom blacklisted word" do
      subject.title = "fooKLTPZYXMbar"
      subject.should_not be_valid
    end
  end

  describe "created with custom blacklist file" do
    before do
      BlacklistValidator.any_instance.should_receive(:get_blacklist_patterns_from).with("blacklist.txt").and_return([])
      BlacklistValidator.any_instance.should_receive(:get_blacklist_patterns_from).with("blacklist-local.txt").and_return([/Kltpzyxm/i])
    end

    it "should be valid when clean" do
      subject.title = "Title"
      subject.should be_valid
    end

    it "should not be valid when it features custom blacklisted word" do
      subject.title = "fooKLTPZYXMbar"
      subject.should_not be_valid
    end
  end
end
