Factory.define :venue do |f|
  f.sequence(:title) { |n| "Venue #{n}" }
  f.sequence(:description) { |n| "Description of Venue #{n}." }
  f.sequence(:address) { |n| "Address #{n}" }
  f.sequence(:street_address) { |n| "Street #{n}" }
  f.sequence(:locality) { |n| "City #{n}" }
  f.sequence(:region) { |n| "Region #{n}" }
  f.sequence(:postal_code) { |n| "#{n}-#{n}-#{n}" }
  f.sequence(:country) { |n| "Country #{n}" }
  f.sequence(:latitude) { |n| "45.#{n}".to_f }
  f.sequence(:longitude) { |n| "122.#{n}".to_f }
  f.sequence(:email) { |n| "info@venue#{n}.com" }
  f.sequence(:telephone) { |n| "(#{n}#{n}#{n}) #{n}#{n}#{n}-#{n}#{n}#{n}#{n}" }
  f.sequence(:url) { |n| "http://#{n}.com" }
  f.closed false
  f.wifi true
  f.access_notes "Access permitted."
end

Factory.define :event_without_venue, :class => Event do |f|
  f.sequence(:title) { |n| "Event #{n}" }
  f.sequence(:description) { |n| "Description of Event #{n}." }
  f.start_time { Time.now + 1.hour }
  f.end_time { self.start_time + 2.hours }
end

Factory.define :event, :parent => :event_without_venue do |f|
  f.association :venue
end

Factory.define :duplicate_event, :parent => :event do |f|
  f.association :duplicate_of, :factory => :event
end

