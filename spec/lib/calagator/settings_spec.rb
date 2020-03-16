# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe 'Calagator.title' do
    around do |example|
      original = Calagator.title
      example.run
      Calagator.title = original
    end

    it 'uses default value' do
      expect(Calagator.title).to eq('Calagator')
    end

    it 'is configurable' do
      Calagator.setup { |config| config.title = 'Calagator Test' }
      expect(Calagator.title).to eq('Calagator Test')
    end
  end
end
