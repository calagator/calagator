# frozen_string_literal: true

Rails.configuration.after_initialize do
  ApplicationRecord.observers << Calagator::CacheObserver
end
