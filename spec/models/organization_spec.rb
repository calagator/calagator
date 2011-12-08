require 'spec_helper'

describe Organization do
  pending "Add tests in #{__FILE__}"

  # Tests for Organization:
  # - We should be able to create a basic org instance given just a name.
  #  -- URL s/be null.
  # - Creating an organization with 'viagra' as name should fail.
  # - Creating an organization without a name is not possible.

  describe "in general" do
    before(:each) do
      @org = Organization.new(:name => "My Organization")
    end
    specify {@org.should be_valid}
  end

  describe "when creating nameless organizations" do
    before(:each) do
      @org = Organization.new()
    end
    specify {@org.should_not be_valid}
  end

  describe "when creating spam" do
    before(:each) do
      @org = Organization.new(:name => "Some like viagra")
    end

    specify {@org.should_not be_valid}
  end

end
