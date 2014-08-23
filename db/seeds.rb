# ruby encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

require 'faker'

def time_rand
  from = 0.0, to = Time.now
  Time.at(from + rand * (to.to_f - from.to_f))
end

100.times do | num |
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
    :access_notes    => Faker::Lorem.paragraph(2),
    )
end

# Fields needed for Events seed data
# 100.times do
#   t.string   "title"
#   t.text     "description"
#   t.datetime "start_time"
#   t.integer  "venue_id" load all venue ids and pick one
#   t.string   "url"
#   t.datetime "created_at",  event start time minus one day
#   t.datetime "updated_at",  event start time minus one day
#   t.datetime "end_time"
#   t.text     "venue_details"
# end
