class ConvertTimesToUtc < ActiveRecord::Migration
  def self.up
    Event.all.each do |e|
      e.start_time = Time.parse(e.start_time_before_type_cast)
      e.save
    end
  end
end
