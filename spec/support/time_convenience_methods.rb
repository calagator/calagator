def now
  Time.zone.now
end

def today
  now.midnight
end

