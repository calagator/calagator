class ConvertTimesToUtc < ActiveRecord::Migration
  def self.up
    Event.find(:all).each do |e|
      e.start_time = Time.parse(e.start_time_before_type_cast)
      e.save
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Cannot migrate down."
  end
end
