require 'spec_helper'

describe ApplicationController, :type => :controller do
  describe "#append_flash" do
    before :each do
      flash.clear
    end

    it "should set flash message if one isn't set already" do
      controller.send(:append_flash, :failure, "Hello.")
      expect(flash[:failure]).to eq "Hello."
    end

    it "should append flash message if one is already set" do
      controller.send(:append_flash, :failure, "Hello.")
      controller.send(:append_flash, :failure, "World.")
      expect(flash[:failure]).to eq "Hello. World."
    end
  end

  describe "#help" do
    it "should respond to a view helper method" do
      expect(controller.send(:help)).to respond_to :link_to
    end

    it "should not respond to an invalid method" do
      expect(controller.send(:help)).not_to respond_to :no_such_method
    end
  end

  describe "#escape_once" do
    let(:raw) { "this & that" }
    let(:escaped) { "this &amp; that" }

    it "should escape raw string" do
      expect(controller.send(:escape_once, raw)).to eq escaped
    end

    it "should not escape an already escaped string" do
      expect(controller.send(:escape_once, escaped)).to eq escaped
    end
  end
end
