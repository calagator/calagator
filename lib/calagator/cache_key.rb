# frozen_string_literal: true

module Calagator
  module CacheKey
    def self.daily_key_for(name, _request = nil)
      "#{name}@#{Time.zone.now.strftime("%Y%m%d")}"
    end
  end
end
