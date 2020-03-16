# frozen_string_literal: true

require 'spec_helper'
require 'calagator/url_prefixer'

module Calagator
  describe UrlPrefixer do
    it 'adds an http prefix to urls missing it' do
      url = described_class.prefix('google.com')
      url.should == 'http://google.com'
    end

    it 'leaves urls with an existing scheme alone' do
      url = described_class.prefix('https://google.com')
      url.should == 'https://google.com'
    end

    it 'leaves blank urls alone' do
      url = described_class.prefix(' ')
      url.should == ' '
    end

    it 'leaves nil urls alone' do
      url = described_class.prefix(nil)
      url.should.nil?
    end

    it 'avoids whitespace inside url' do
      url = described_class.prefix(' google.com ')
      url.should == 'http://google.com '
    end
  end
end
