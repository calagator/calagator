FactoryGirl.define do
  factory :venue do
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

  factory :event do
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
