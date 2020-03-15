# frozen_string_literal: true

ActiveRecord::Base.observers << Calagator::CacheObserver
