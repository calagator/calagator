class Venue < ActiveRecord::Base
  class Search < Struct.new(:venues, :tag, :most_active_venues, :newest_venues, :scoped_venues)
    def initialize(params)
      scoped_venues = Venue.non_duplicates

      # Pick a subset of venues (we want in_business by default)
      if params[:include_closed]
        scoped_venues = scoped_venues
      elsif params[:closed]
        scoped_venues = scoped_venues.out_of_business
      else
        scoped_venues = scoped_venues.in_business
      end

      # Support old ajax autocomplete parameter name
      params[:term] = params[:val] if params[:val]

      @tag = nil
      if params[:tag].present? # searching by tag
        @tag = params[:tag]
        @venues = scoped_venues.tagged_with(@tag)
      elsif params.has_key?(:query) || params.has_key?(:term) || params[:all] == '1' # searching by query
        scoped_venues = scoped_venues.with_public_wifi if params[:wifi]

        if params[:term].present? # for the ajax autocomplete widget
          conditions = ["title LIKE ?", "%#{params[:term]}%"]
          @venues = scoped_venues.where(conditions).order('LOWER(title)')
        elsif params[:query].present?
          @venues = Venue.search(params[:query], :include_closed => params[:include_closed], :wifi => params[:wifi])
        else
          @venues = scoped_venues.all
        end
      else # default view
        @most_active_venues = scoped_venues.limit(10).order('events_count DESC')
        @newest_venues = scoped_venues.limit(10).order('created_at DESC')
      end

      self.venues = @venues
      self.tag = @tag
      self.most_active_venues = @most_active_venues
      self.newest_venues = @newest_venues
      self.scoped_venues = scoped_venues
    end
  end
end

