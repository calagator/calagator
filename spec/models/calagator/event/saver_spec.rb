# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe Event::Saver do
    let(:event) { build :event }
    let(:imported_event) { create :event, :with_source }
    let(:params) { { venue_name: 'Name of Venue' } }

    describe '#save' do
      it 'saves a valid event' do
        saver = described_class.new(event, params)
        saver.save
        expect(saver.failure).to be_nil
      end

      it 'fails to save an event with too many links' do
        event.description = "http://google.com\n
                            http://example.com\n
                            http://calagator.com\n
                            http://disallowed.link"
        saver = described_class.new(event, params)
        saver.save
        expect(saver.failure).to include 'too many links'
      end

      it 'fails to save an event made by an evil robot' do
        params[:trap_field] = "It's a trap!"
        saver = described_class.new(event, params)
        saver.save
        expect(saver.failure).to include "you're an evil robot"
      end

      it 'does not save an event being previewed' do
        params[:preview] = 'Preview'
        saver = described_class.new(event, params)
        expect(saver.save).to be false
      end

      it 'saves a valid imported event with more than 3 links' do
        saver = described_class.new(imported_event, params)
        saver.save
        expect(saver.failure).to be_nil
      end

      it 'fails to save an imported event with links added' do
        params[:event] = { description: "#{imported_event.description}\n\nhttp://disallowed.link" }
        saver = described_class.new(imported_event, params)
        saver.save
        expect(saver.failure).to include 'too many links'
      end
    end
  end
end
