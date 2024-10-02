---
title: Seed file
---
# Introduction

This document will walk you through the implementation of the seed file feature.

The feature seeds the database with sample data for development and testing purposes.

We will cover:

1. Overview of the seed file.
2. Purpose of the seed data.
3. Important areas of the code.

# Overview

The seed file is located at <SwmPath>[db/seeds.rb](/db/seeds.rb)</SwmPath>. It uses the <SwmToken path="/db/seeds.rb" pos="4:4:4" line-data="  require &#39;faker&#39;">`faker`</SwmToken> and <SwmToken path="/db/seeds.rb" pos="5:4:4" line-data="  require &#39;factory_bot_rails&#39;">`factory_bot_rails`</SwmToken> gems to generate sample data.

# Purpose

The purpose of this seed file is to populate the database with realistic sample data for development and testing. This helps developers work with a populated database without manually entering data.

# Important areas of code

## Loading dependencies

<SwmSnippet path="/db/seeds.rb" line="1">

---

We start by ensuring the necessary gems are loaded. If they are not available, the script exits with an error message.

```
# frozen_string_literal: true

begin
  require 'faker'
  require 'factory_bot_rails'
rescue LoadError
  puts "Calagator's seeds require faker and factory_bot_rails."
  puts 'Add them to your gemfile and try again.'
  exit 1
end
```

---

</SwmSnippet>

## Defining the venue factory

<SwmSnippet path="/db/seeds.rb" line="11">

---

We define a factory for creating venue records. This factory uses <SwmToken path="/db/seeds.rb" pos="14:5:5" line-data="    title           { Faker::Company.name }">`Faker`</SwmToken> to generate realistic data for each attribute.

```

FactoryBot.define do
  factory :seed_venue, class: Calagator::Venue do
    title           { Faker::Company.name }
    description     { Faker::Lorem.paragraph }
    address         do
      "#{Faker::Address.street_address},
                       #{Faker::Address.city},
                       #{Faker::Address.state}
                       #{Faker::Address.zip_code}"
    end
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
    access_notes    { Faker::Lorem.paragraph }
```

---

</SwmSnippet>

## Adding events to venues

<SwmSnippet path="/db/seeds.rb" line="35">

---

We add a trait to the venue factory to create associated events. This ensures that some venues have events linked to them.

```

    trait :with_events do
      after(:create) do |seed_venue|
        create_list(:seed_event, 3, venue_id: seed_venue.id)
      end
    end
  end
```

---

</SwmSnippet>

## Defining the event factory

<SwmSnippet path="/db/seeds.rb" line="42">

---

We define a factory for creating event records. This factory also uses <SwmToken path="/db/seeds.rb" pos="47:5:5" line-data="    title       { Faker::Lorem.sentence }">`Faker`</SwmToken> to generate realistic data for each attribute.

```

  factory :seed_event, class: Calagator::Event do
    from = 2.years.ago
    to = 2.years.from_now

    title       { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    start_time  do
      [
        Faker::Time.between(from: 2.years.ago, to: 2.years.from_now),
        Faker::Time.backward(days: 1),
        Faker::Time.forward(days: 1),
        Faker::Time.forward(days: 7)
      ].sample
    end
    created_at  { start_time - 1.day }
    end_time    { start_time + 3.hours }
```

---

</SwmSnippet>

## Adding venues to events

<SwmSnippet path="/db/seeds.rb" line="59">

---

We add a trait to the event factory to create associated venues. This ensures that some events have venues linked to them.

```

    trait :with_venue do
      before(:create) do |seed_event|
        venue = create(:seed_venue)
        seed_event.venue_id = venue.id
      end
    end
  end
end
```

---

</SwmSnippet>

## Seeding the database

<SwmSnippet path="/db/seeds.rb" line="68">

---

Finally, we seed the database with sample data. We create 25 venues with events, 25 venues without events, 25 events with venues, and 25 events without venues.

```

puts 'Seeding database with sample data...'
FactoryBot.create_list(:seed_venue, 25, :with_events)
FactoryBot.create_list(:seed_venue, 25)
FactoryBot.create_list(:seed_event, 25, :with_venue)
FactoryBot.create_list(:seed_event, 25)
```

---

</SwmSnippet>

# Conclusion

This seed file helps developers by providing a quick way to populate the database with realistic sample data. This is essential for testing and development, ensuring that the application behaves as expected with a populated database.

<SwmMeta version="3.0.0" repo-id="Z2l0aHViJTNBJTNBY2FsYWdhdG9yJTNBJTNBY2hyaXNicnVt" repo-name="calagator"><sup>Powered by [Swimm](https://app.swimm.io/)</sup></SwmMeta>
