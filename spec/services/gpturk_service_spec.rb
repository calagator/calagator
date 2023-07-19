# Gemfile
# ...
gem 'webmock'
# ...

# spec/services/gpturk_service_spec.rb

require 'rails_helper'
require 'webmock/rspec'

describe GpturkService do
  before do
    # Stub requests
    stub_request(:post, /gpturk.cognitivesurpl.us/)
  end

  describe '#is_this_spam?' do
    it 'returns true if label is 0' do
      allow(GpturkService).to receive(:get_spam_label).and_return(0)
      expect(GpturkService.is_this_spam?('some text')).to be true
    end

    it 'returns false if label is not 0' do
      allow(GpturkService).to receive(:get_spam_label).and_return(1)
      expect(GpturkService.is_this_spam?('some text')).to be false
    end
  end

  describe '#get_spam_label' do
    let(:url) { "https://gpturk.cognitivesurpl.us/api/tasks/#{ENV['GPTURK_SPAM_MODEL_ID']}/inferences" }

    context 'when request is successful' do
      before do
        stub_request(:post, url).to_return(status: 200, body: { label: { parsed_label: 1 } }.to_json)
      end

      it 'returns the parsed label' do
        expect(GpturkService.get_spam_label('some text')).to eq(1)
      end
    end

    context 'when an HTTP error occurs' do
      before do
        stub_request(:post, url).to_return(status: [500, "Internal Server Error"])
      end

      it 'returns 1' do
        expect(GpturkService.get_spam_label('some text')).to eq(1)
      end
    end

    context 'when a timeout occurs' do
      before do
        stub_request(:post, url).to_timeout
      end

      it 'returns 1' do
        expect(GpturkService.get_spam_label('some text')).to eq(1)
      end
    end

    context 'when a network error occurs' do
      before do
        stub_request(:post, url).to_raise(SocketError.new)
      end

      it 'returns 1' do
        expect(GpturkService.get_spam_label('some text')).to eq(1)
      end
    end
  end
end
