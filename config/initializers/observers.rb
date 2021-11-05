# frozen_string_literal: true

ApplicationRecord.observers << Calagator::CacheObserver
