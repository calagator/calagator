# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :venue, class: 'Calagator::Venue' do
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
    closed { false }
    wifi { true }
    access_notes { 'Access permitted.' }
    after(:create) do
      Sunspot.commit if Calagator::Venue::SearchEngine.kind == :sunspot
    end

    trait :with_multiple_tags do
      after(:create) { |venue| venue.tag_list = 'tag1, tag2'; venue.save }
    end
  end

  factory :event, class: 'Calagator::Event' do
    sequence(:title) { |n| "Event #{n}" }
    sequence(:description) { |n| "Description of Event #{n}." }
    start_time { Time.zone.now.beginning_of_day }
    end_time { start_time + 1.hour }
    after(:create) do
      Sunspot.commit if Calagator::Event::SearchEngine.kind == :sunspot
    end

    trait :with_venue do
      association :venue
    end

    trait :with_multiple_tags do
      after(:create) { |event| event.tag_list = 'tag1, tag2'; event.save }
    end

    trait :with_source do
      association :source
      sequence(:description) do |n|
        "Description of Event #{n}.\n
        http://test.com\n
        http://example.com\n
        http://google.com\n
        http://yahoo.com"
      end
    end
  end

  factory :duplicate_event, parent: :event do
    association :duplicate_of, factory: :event
  end

  factory :source, class: 'Calagator::Source' do
    sequence(:title) { |n| "Source #{n}" }
    url { 'http://example.com' }
  end
end
