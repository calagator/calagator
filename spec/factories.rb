Factory.define :venue do |f|
  f.sequence(:title) { |n| "Venue #{n}" }
  f.sequence(:description) { |n| "Description of Venue #{n}." }
  f.sequence(:street_address) { |n| "Street #{n}" }
  f.sequence(:locality) { |n| "City #{n}" }
  f.sequence(:region) { |n| "region #{n}" }
  f.sequence(:postal_code) { |n| "#{n}-#{n}-#{n}" }
  f.sequence(:country) { |n| "Country #{n}" }
  f.sequence(:latitude) { |n| n }
  f.sequence(:longitude) { |n| n }
  f.sequence(:email) { |n| "info@venue#{n}.com" }
  f.sequence(:telephone) { |n| "(#{n}#{n}#{n}) #{n}#{n}#{n}-#{n}#{n}#{n}#{n}" }
  f.closed false
  f.wifi true
  f.access_notes "Access permitted."
end

Factory.define :event_without_venue, :class => Event do |f|
  f.sequence(:title) { |n| "Event #{n}" }
  f.sequence(:description) { |n| "Description of Event #{n}." }
  f.start_time { Time.now + 1.hour }
  f.end_time { Time.now + 2.hours }
end

Factory.define :event, :parent => :event_without_venue do |f|
  f.association :venue
end

Factory.define :duplicate_event, :parent => :event do |f|
  f.association :duplicate_of, :factory => :event
end

