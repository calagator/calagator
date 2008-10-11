require File.dirname(__FILE__) + '/../spec_helper'
include ApplicationHelper

describe ApplicationHelper do
  describe "when escaping HTML while preserving entities (cleanse)" do
    it "should preserve plain text" do
      cleanse("Allison to Lillia").should == "Allison to Lillia"
    end
    
    it "should escape HTML" do
      cleanse("<Fiona>").should == "&lt;Fiona&gt;"
    end

    it "should preserve HTML entities" do
      cleanse("Allison &amp; Lillia").should == "Allison &amp; Lillia"
    end

    it "should handle text, HTML and entities together" do
      cleanse("&quot;<Allison> &amp; Lillia&quot;").should == "&quot;&lt;Allison&gt; &amp; Lillia&quot;"
    end
  end
end
