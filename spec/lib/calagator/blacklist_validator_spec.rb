require "active_model"
require "calagator/blacklist_validator"

module Calagator

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
      expect(subject).to be_valid
    end

    it "should not be valid when it features blacklisted word" do
      subject.title = "Foo bar cialis"
      expect(subject).not_to be_valid
    end
  end

  describe "with custom blacklist" do
    before do
      klass.validates :title, blacklist: { patterns: [/Kltpzyxm/i] }
    end

    it "should be valid when clean" do
      subject.title = "Title"
      expect(subject).to be_valid
    end

    it "should not be valid when it features custom blacklisted word" do
      subject.title = "fooKLTPZYXMbar"
      expect(subject).not_to be_valid
    end
  end

  describe "created with custom blacklist file" do
    let(:blacklist_file_path) { Rails.root.join("config/blacklist.txt") }

    before do
      allow(File).to receive(:exists?).with(blacklist_file_path).and_return(true)
      expect(File).to receive(:readlines).with(blacklist_file_path).and_return(["Kltpzyxm"])
    end

    it "should be valid when clean" do
      subject.title = "Title"
      expect(subject).to be_valid
    end

    it "should not be valid when it features custom blacklisted word" do
      subject.title = "fooKLTPZYXMbar"
      expect(subject).not_to be_valid
    end
  end
end

end
