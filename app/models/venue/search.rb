class Venue < ActiveRecord::Base
  class Search < Struct.new(:params)
    def venues
      @venues ||= if query
        Venue.search(query, include_closed: include_closed?, wifi: wifi?)
      else
        base.business.wifi.search.scope
      end
    end

    def most_active_venues
      base.business.wifi.scope.order('events_count DESC').limit(10)
    end

    def newest_venues
      base.business.wifi.scope.order('created_at DESC').limit(10)
    end

    def results?
      !query && !tag && !all?
    end

    def tag
      params[:tag]
    end

    def query
      params[:query]
    end

    def wifi?
      params[:wifi]
    end

    def all?
      params[:all] == '1'
    end

    protected

    def base
      @scope = Venue.non_duplicates
      self
    end

    def business
      if only_closed?
        @scope = @scope.out_of_business
      elsif only_open?
        @scope = @scope.in_business
      end
      self
    end

    def wifi
      @scope = @scope.with_public_wifi if wifi?
      self
    end

    def search
      @scope = @scope.tagged_with(tag) if tag.present? # searching by tag
      self
    end

    def scope
      @scope
    end

    private

    def only_closed?
      params[:closed]
    end

    def only_open?
      !include_closed?
    end

    def include_closed?
      params[:include_closed]
    end
  end
end

