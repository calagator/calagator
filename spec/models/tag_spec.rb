require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  describe "when parsing tags" do
    it "should handle single-item string" do
      Tag.parse_tags("foo").should == ["foo"]
    end

    it "should handle multi-item delimited string" do
      Tag.parse_tags("foo, bar").should == ["foo", "bar"]
    end

    it "should handle single-item array" do
      Tag.parse_tags(["foo"]).should == ["foo"]
    end

    it "should handle multi-item arrays" do
      Tag.parse_tags(["foo", "bar"]).should == ["foo", "bar"]
    end

    it "should handle single-item delimited array" do
      Tag.parse_tags(["foo, bar"]).should == ["foo", "bar"]
    end
  end
end
