# frozen_string_literal: true

require 'active_model'
require 'calagator/denylist_validator'

module Calagator
  describe DenylistValidator do
    subject { klass.new }

    let(:klass) do
      Class.new do
        include ActiveModel::Validations
        validates :title, denylist: true
        attr_accessor :title
      end
    end

    describe 'with default denylist' do
      it 'is valid when clean' do
        subject.title = 'Title'
        expect(subject).to be_valid
      end

      it 'is not valid when it features denylisted word' do
        subject.title = 'Foo bar cialis'
        expect(subject).not_to be_valid
      end
    end

    describe 'with custom denylist' do
      before do
        klass.validates :title, denylist: { patterns: [/Kltpzyxm/i] }
      end

      it 'is valid when clean' do
        subject.title = 'Title'
        expect(subject).to be_valid
      end

      it 'is not valid when it features custom denylisted word' do
        subject.title = 'fooKLTPZYXMbar'
        expect(subject).not_to be_valid
      end
    end

    describe 'created with custom denylist file' do
      let(:denylist_file_path) { Rails.root.join('config/denylist.txt') }

      before do
        allow(File).to receive(:exist?).with(denylist_file_path).and_return(true)
        expect(File).to receive(:readlines).with(denylist_file_path).and_return(['Kltpzyxm'])
      end

      it 'is valid when clean' do
        subject.title = 'Title'
        expect(subject).to be_valid
      end

      it 'is not valid when it features custom denylisted word' do
        subject.title = 'fooKLTPZYXMbar'
        expect(subject).not_to be_valid
      end
    end
  end
end
