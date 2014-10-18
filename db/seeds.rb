# ruby encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

require 'faker'
require 'active_support/core_ext'

def rand_date
  date = DateTime.current
  date.change(:year => (date.year + rand(-2..2)), 
              :month => rand(1..12), 
              :day => rand(1..28), 
              :hour => rand(1..24))
end

100.times do
  mock_loc = Faker::Address
  mock_web = Faker::Internet
  mock_num = Faker::Number

  Venue.create!(
    :title           => Faker::Company.name,
    :address         => "#{mock_loc.street_address},
                         #{mock_loc.city},
                         #{mock_loc.state}
                         #{mock_loc.zip_code}",
    :url             => mock_web.url,
    :street_address  => mock_loc.street_address,
    :locality        => mock_loc.city,
    :region          => mock_loc.state,
    :postal_code     => mock_loc.zip_code,
    :country         => mock_loc.country,
    :latitude        => mock_loc.latitude,
    :longitude       => mock_loc.longitude,
    :email           => mock_web.email,
    :telephone       => Faker::PhoneNumber.phone_number,
    :closed          => [true, false].sample,
    :wifi            => [true, false].sample,
    :access_notes    => Faker::Lorem.paragraph,
    )
end

venue_ids = Venue.all(:select => :id).collect(&:id)

1000.times do
  event_date = rand_date
  selected_id = venue_ids[rand(0..venue_ids.length)]

  Event.create!(
  :title          => Faker::Lorem.sentence,
  :description    => Faker::Lorem.paragraph,
  :start_time     => event_date,
  :venue_id       => selected_id,
  :url            => Faker::Internet.url,
  :created_at     => event_date - 1.days,
  :end_time       => event_date + 3.hours,
  :venue_details  => Faker::Lorem.paragraph
  )
end
