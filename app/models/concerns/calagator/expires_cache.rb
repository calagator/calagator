# frozen_string_literal: true

module Calagator
  module ExpiresCache
    extend ActiveSupport::Concern

    included do
      after_commit :expire_cache
    end

    private

    def expire_cache
      Rails.logger.info "#{self.class.name} cache expiration: clearing all"
      Rails.cache.clear
    end
  end
end
