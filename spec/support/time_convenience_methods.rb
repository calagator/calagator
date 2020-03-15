# frozen_string_literal: true

def now
  Time.zone.now
end

def today
  now.midnight
end
