class Venue < ActiveRecord::Base
  class Search < Struct.new(:params, :venues, :most_active_venues, :newest_venues, :scoped_venues)
    def initialize(params)
      self.params = params
      venues
    end

    def venues
      @venues ||= base.in_business.wifi.stuff
    end

    def tag
      params[:tag]
    end

    protected

    def base
      @scope = Venue.non_duplicates
      self
    end

    def in_business
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

    def stuff
      if tag.present? # searching by tag
        @scope.tagged_with(tag)
      elsif term.present? # for the ajax autocomplete widget
        conditions = ["title LIKE ?", "%#{term}%"]
        @scope.where(conditions).order('LOWER(title)')
      elsif query
        Venue.search(query, include_closed: include_closed?, wifi: wifi?)
      elsif !all # default view
        self.most_active_venues = @scope.limit(10).order('events_count DESC')
        self.newest_venues = @scope.limit(10).order('created_at DESC')
        self.scoped_venues = @scope
        nil
      else
        @scope
      end
    end

    private

    # Support old ajax autocomplete parameter name
    def term
      params[:val] || params[:term]
    end

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

