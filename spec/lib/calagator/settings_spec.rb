require 'spec_helper'

module Calagator
  describe 'Calagator.title' do
    it "should use default value" do
      expect(Calagator.title).to eq('Calagator')
    end

    it "should be configurable" do
      Calagator.setup { |config| config.title = 'Calagator Test' }
      expect(Calagator.title).to eq('Calagator Test')
    end

    around do |example|
      original = Calagator.title
      example.run
      Calagator.title = original
    end
  end
end
