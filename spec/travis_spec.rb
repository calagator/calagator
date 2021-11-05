# frozen_string_literal: true

if ENV['DB']
  describe 'travis matrix' do
    it 'is testing the right db' do
      expect(ApplicationRecord.connection_config[:adapter]).to include ENV['DB']
    end
  end
end
