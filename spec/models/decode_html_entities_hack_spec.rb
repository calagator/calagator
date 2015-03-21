require 'spec_helper'

# Non-database model derived from: http://railscasts.com/episodes/219-active-model
class ModelWithoutDecodeHack
  include ActiveModel::Callbacks
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  define_callbacks :validate

  attr_accessor :kitten

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def attributes
    { :kitten => kitten }
  end
end

# Same as above but with the mixin
class ModelWithDecodeHack < ModelWithoutDecodeHack
  include DecodeHtmlEntitiesHack
end

describe DecodeHtmlEntitiesHack, :type => :model do
  let(:encoded_string) { "cute &amp; furry" }
  let(:decoded_string) { "cute & furry" }

  it "should not modify attributes in models that don't include it" do
    record = ModelWithoutDecodeHack.new(:kitten => encoded_string)
    expect(record).to be_valid
    expect(record.kitten).to eq encoded_string
  end

  it "should modify attributes in models that include it" do
    record = ModelWithDecodeHack.new(:kitten => encoded_string)
    expect(record).to be_valid
    expect(record.kitten).to eq decoded_string
  end

end
