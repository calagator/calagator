# `ri_cal` relies on a monkeypatch that was removed in Rails 3.1. This adds it back because `ri_cal` hasn't been updated to deal with this.
class Time
  unless respond_to?(:get_zone)
    def self.get_zone(time_zone)
      return self.find_zone(time_zone)
    end
  end
end
