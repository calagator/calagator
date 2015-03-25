# ruby encoding: utf-8

begin
  require 'faker'
  require 'factory_girl'
rescue LoadError
  puts "Calagator's seeds require faker and factory_girl."
  puts "Add them to your gemfile and try again."
  exit 1
end

FactoryGirl.define do
  factory :seed_venue, class: Calagator::Venue do
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

  factory :seed_event, class: Calagator::Event do
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

puts "Seeding database with sample data..."
FactoryGirl.create_list(:seed_venue, 25, :with_events)
FactoryGirl.create_list(:seed_venue, 25)
FactoryGirl.create_list(:seed_event, 25, :with_venue)
FactoryGirl.create_list(:seed_event, 25)
