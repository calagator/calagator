FactoryGirl.define do
  factory :venue do
    sequence(:title) { |n| "Venue #{n}" }
    sequence(:description) { |n| "Description of Venue #{n}." }
    sequence(:address) { |n| "Address #{n}" }
    sequence(:street_address) { |n| "Street #{n}" }
    sequence(:locality) { |n| "City #{n}" }
    sequence(:region) { |n| "Region #{n}" }
    sequence(:postal_code) { |n| "#{n}-#{n}-#{n}" }
    sequence(:country) { |n| "Country #{n}" }
    sequence(:latitude) { |n| "45.#{n}".to_f }
    sequence(:longitude) { |n| "122.#{n}".to_f }
    sequence(:email) { |n| "info@venue#{n}.com" }
    sequence(:telephone) { |n| "(#{n}#{n}#{n}) #{n}#{n}#{n}-#{n}#{n}#{n}#{n}" }
    sequence(:url) { |n| "http://#{n}.com" }
    closed false
    wifi true
    access_notes "Access permitted."
    after(:create) { Sunspot.commit if Venue::SearchEngine.kind == :sunspot }
  end

  factory :event do
    sequence(:title) { |n| "Event #{n}" }
    sequence(:description) { |n| "Description of Event #{n}." }
    start_time { Time.now + 1.hour }
    end_time { start_time + 1.hour }
    after(:create) { Sunspot.commit if Event::SearchEngine.kind == :sunspot }

    trait :with_venue do
      association :venue
    end
  end

  factory :duplicate_event, :parent => :event do
    association :duplicate_of, :factory => :event
  end

  factory :seed_venue do
    title { Faker::Company.name }
    description { Faker::Lorem.paragraph }
    address { "#{Faker::Address.street_address},
      #{Faker::Address.city},
      #{Faker::Address.state}
      #{Faker::Address.zip_code}" }
    street_address { Faker::Address.street_address }
    locality { Faker::Address.city }
    region { Faker::Address.state }
    postal_code { [Faker::Address.zip_code, Faker::Address.postcode].sample }
    country { Faker::Address.country }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    email { Faker::Internet.email }
    telephone { Faker::PhoneNumber.phone_number }
    url { Faker::Internet.url }
    closed [true, false].sample
    wifi [true, false].sample
    access_notes Faker::Lorem.paragraph

    after(:create) do | venue |
      create(:event, venue: venue)
    end

  end

  factory :seed_event do
    from = 2.years.ago
    to = 2.years.from_now

    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    start_time { [Faker::Time.between(from, to),
                  Date.today,
                  Date.tomorrow,
                  1.week.from_now].sample }
    created_at { start_time - 1.days }
    end_time { start_time + 3.hours }
    venue

    trait :with_venue do
      association :venue
    end
  end
end
