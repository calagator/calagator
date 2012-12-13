require 'spec_helper'

describe ApplicationController do
  describe "#append_flash" do
    before :each do
      flash.clear
    end

    it "should set flash message if one isn't set already" do
      controller.send(:append_flash, :failure, "Hello.")
      flash[:failure].should eq "Hello."
    end

    it "should append flash message if one is already set" do
      controller.send(:append_flash, :failure, "Hello.")
      controller.send(:append_flash, :failure, "World.")
      flash[:failure].should eq "Hello. World."
    end
  end

  describe "#help" do
    it "should respond to a view helper method" do
      controller.send(:help).should respond_to :link_to
    end

    it "should not respond to an invalid method" do
      controller.send(:help).should_not respond_to :no_such_method
    end
  end

  describe "#escape_once" do
    let(:raw) { "this & that" }
    let(:escaped) { "this &amp; that" }

    it "should escape raw string" do
      controller.send(:escape_once, raw).should eq escaped
    end

    it "should not escape an already escaped string" do
      controller.send(:escape_once, escaped).should eq escaped
    end
  end
end
