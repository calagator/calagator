class Venue < ActiveRecord::Base
  class Search < Struct.new(:params)
    def venues
      @venues ||= if query
        Venue.search(query, include_closed: include_closed?, wifi: wifi?)
      else
        base.business.wifi.search
      end
    end

    def tag
      params[:tag]
    end

    def most_active_venues
      base.business.scope.order('events_count DESC').limit(10)
    end

    def newest_venues
      base.business.scope.order('created_at DESC').limit(10)
    end

    def scoped_venues
      @scope
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
      if tag.present? # searching by tag
        @scope.tagged_with(tag)
      elsif all
        @scope
      else # default view
        nil
      end
    end

    def scope
      @scope
    end

    private

    def query
      params[:query]
    end

    def only_closed?
      params[:closed]
    end

    def only_open?
      !include_closed?
    end

    def include_closed?
      params[:include_closed]
    end

    def wifi?
      params[:wifi]
    end

    def all
      params[:all] == '1'
    end
  end
end

