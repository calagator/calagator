class Event < ActiveRecord::Base
  class Saver < Struct.new(:event, :params, :venue, :failure)
    def save
      self.venue = event.associate_with_venue(venue_ref)

      event.attributes = params[:event]
      event.start_time = [ params[:start_date], params[:start_time] ]
      event.end_time   = [ params[:end_date], params[:end_time] ]
      event.tags.reload # Reload the #tags association because its members may have been modified when #tag_list was set above.

      attempt_save?
    end

    def has_new_venue?
      return unless venue
      venue.previous_changes["id"] == [nil, venue.id] && params[:venue_name].present?
    end

    private

    # Venues may be referred to in the params hash either by id or by name. This
    # method looks for whichever type of reference is present and returns that
    # reference. If both a venue id and a venue name are present, then the venue
    # id is returned.
    #
    # If a venue id is returned it is cast to an integer for compatibility with
    # Event#associate_with_venue.
    def venue_ref
      if (params[:event] && params[:event][:venue_id].present?)
        params[:event][:venue_id].to_i
      else
        params[:venue_name]
      end
    end

    def attempt_save?
      !spam? && !preview? && event.save
    end

    def spam?
      evil_robot? || too_many_links?
    end

    def evil_robot?
      if params[:trap_field].present?
        self.failure = "<h3>Evil Robot</h3> We didn't save this event because we think you're an evil robot. If you're really not an evil robot, look at the form instructions more carefully. If this doesn't work please file a bug report and let us know."
      end
    end

    def too_many_links?
      if event.description.present? && event.description.scan(/https?:\/\//i).size > 3
        self.failure = "We allow a maximum of 3 links in a description. You have too many links."
      end
    end

    def preview?
      if params[:preview]
        event.valid?
      end
    end
  end
end

