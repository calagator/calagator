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
    start_time { today + 1.hour }
    end_time { start_time + 1.hour }
    after(:create) { Sunspot.commit if Event::SearchEngine.kind == :sunspot }

    trait :with_venue do
      association :venue
    end
  end

  factory :duplicate_event, parent: :event do
    association :duplicate_of, factory: :event
  end

  factory :seed_venue, parent: :venue do
    title           { Faker::Company.name }
    description     { Faker::Lorem.paragraph }
    address         { "#{Faker::Address.street_address},
                       #{Faker::Address.city},
                       #{Faker::Address.state}
                       #{Faker::Address.zip_code}" }
    street_address  { Faker::Address.street_address }
    locality        { Faker::Address.city }
    region          { Faker::Address.state }
    postal_code     { [Faker::Address.zip_code, Faker::Address.postcode].sample }
    country         { Faker::Address.country }
    latitude        { Faker::Address.latitude }
    longitude       { Faker::Address.longitude }
    email           { Faker::Internet.email }
    telephone       { Faker::PhoneNumber.phone_number }
    url             { Faker::Internet.url }
    closed          { [false, true].sample }
    wifi            { [true, false].sample }
    access_notes    Faker::Lorem.paragraph

    trait :with_events do
      after(:create) do | seed_venue |
        create_list(:seed_event, 3, venue_id: seed_venue.id)
      end
    end

  end

  factory :seed_event, parent: :event do
    from = 2.years.ago
    to = 2.years.from_now

    title       { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    start_time  {
      [
        Faker::Time.between(2.years.ago, 2.years.from_now),
        Faker::Time.backward(1, :all),
        Faker::Time.forward(1, :all),
        Faker::Time.forward(7, :all)
      ].sample
    }
    created_at  { start_time - 1.days }
    end_time    { start_time + 3.hours }

    trait :with_venue do
      before(:create) do |seed_event|
        venue = create(:seed_venue)
        seed_event.venue_id = venue.id
      end
    end
  end
end
