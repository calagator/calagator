FactoryGirl.define do
  factory :venue do
    mock_loc = Faker::Address
    mock_web = Faker::Internet
    mock_num = Faker::Number

    title { Faker::Company.name }
    description { Faker::Lorem.paragraph }
    address { "#{mock_loc.street_address},
      #{mock_loc.city},
      #{mock_loc.state}
      #{mock_loc.zip_code}" }
    street_address { mock_loc.street_address }
    locality { mock_loc.city }
    region { mock_loc.state }
    postal_code { [mock_loc.zip_code, mock_loc.postcode].sample }
    country { mock_loc.country }
    latitude { mock_loc.latitude }
    longitude { mock_loc.longitude }
    email { mock_web.email }
    telephone { Faker::PhoneNumber.phone_number }
    url { mock_web.url }
    closed [true, false].sample
    wifi [true, false].sample
    access_notes Faker::Lorem.paragraph

    after(:create) do | venue |
      create(:event, venue: venue)
    end

  end

  factory :event do
    from = ::Date.today - (2*365)
    to = ::Date.today + (2*365)

    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    start_time { [Faker::Time.between(from, to), 
      ::Date.today, 
      ::Date.tomorrow, 
      1.week.from_now].sample }
    created_at { start_time - 1.days }
    end_time { start_time + 3.hours }
    venue

  end

  factory :duplicate_event, :parent => :event do
    association :duplicate_of, :factory => :event
  end
end
