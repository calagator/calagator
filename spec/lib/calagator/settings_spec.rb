require 'spec_helper'

module Calagator
  describe 'Calagator.test' do
    it "should use default" do
      expect(Calagator.test).to eq('it works')
    end
  end

  describe 'Calagator.title' do
    it "should use initializer's value" do
      expect(Calagator.title).to eq('Calagator Dummy')
    end

    it "should be configurable" do
      Calagator.setup { |config| config.title = 'Calagator Test' }
      expect(Calagator.title).to eq('Calagator Test')
      Calagator.setup { |config| config.title = 'Calagator Dummy' }
    end
  end
end
