# frozen_string_literal: true

require 'spec_helper'

module Calagator
  describe ApplicationController, type: :controller do
    describe '#append_flash' do
      before do
        flash.clear
      end

      it "sets flash message if one isn't set already" do
        controller.send(:append_flash, :failure, 'Hello.')
        expect(flash[:failure]).to eq 'Hello.'
      end

      it 'appends flash message if one is already set' do
        controller.send(:append_flash, :failure, 'Hello.')
        controller.send(:append_flash, :failure, 'World.')
        expect(flash[:failure]).to eq 'Hello. World.'
      end
    end

    describe '#help' do
      it 'responds to a view helper method' do
        expect(controller.send(:help)).to respond_to :link_to
      end

      it 'does not respond to an invalid method' do
        expect(controller.send(:help)).not_to respond_to :no_such_method
      end
    end

    describe '#escape_once' do
      let(:raw) { 'this & that' }
      let(:escaped) { 'this &amp; that' }

      it 'escapes raw string' do
        expect(controller.send(:escape_once, raw)).to eq escaped
      end

      it 'does not escape an already escaped string' do
        expect(controller.send(:escape_once, escaped)).to eq escaped
      end
    end

    describe '#recaptcha_enabled?' do
      subject do
        result = nil

        Recaptcha.with_configuration(site_key: temporary_key) do
          result = controller.send(:recaptcha_enabled?)
        end

        result
      end

      let(:temporary_key) { nil }

      context 'when Recaptcha site_key is not set' do
        it { is_expected.to be_falsey }
      end

      context 'when ENV key is set' do
        let(:temporary_key) { 'asdf' }

        it { is_expected.to be_truthy }
      end
    end
  end
end
