module TimeZoneHelpers
 def self.randomize_time_zone!
    Time.zone = ActiveSupport::TimeZone.all.sample
    puts "Randomized with Time.zone = #{Time.zone.name.inspect}"
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    TimeZoneHelpers.randomize_time_zone!
  end
end
