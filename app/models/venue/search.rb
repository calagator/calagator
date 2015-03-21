class Venue < ActiveRecord::Base
  class Search < Struct.new(:tag, :query, :wifi, :all, :closed, :include_closed)
    def initialize attributes = {}
      members.each do |key|
        send "#{key}=", attributes[key]
      end
    end

    def venues
      @venues ||= if query
        Venue.search(query, include_closed: include_closed, wifi: wifi)
      else
        base.business.wifi_status.search.scope
      end
    end

    def most_active_venues
      base.business.wifi_status.scope.order('events_count DESC').limit(10)
    end

    def newest_venues
      base.business.wifi_status.scope.order('created_at DESC').limit(10)
    end

    def results?
      query || tag || all
    end

    protected

    def base
      @scope = Venue.non_duplicates
      self
    end

    def business
      if closed
        @scope = @scope.out_of_business
      elsif !include_closed
        @scope = @scope.in_business
      end
      self
    end

    def wifi_status
      @scope = @scope.with_public_wifi if wifi
      self
    end

    def search
      @scope = @scope.tagged_with(tag) if tag.present? # searching by tag
      self
    end

    def scope
      @scope
    end
  end
end

