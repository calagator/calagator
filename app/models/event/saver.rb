class Event < ActiveRecord::Base
  class Saver < Struct.new(:event, :params, :failure)
    def save
      event.attributes = params[:event]
      event.venue      = find_or_initialize_venue
      event.start_time = [ params[:start_date], params[:start_time] ]
      event.end_time   = [ params[:end_date], params[:end_time] ]
      event.tags.reload # Reload the #tags association because its members may have been modified when #tag_list was set above.

      attempt_save?
    end

    def has_new_venue?
      return unless event.venue
      event.venue.previous_changes["id"] == [nil, event.venue.id] && params[:venue_name].present?
    end

    private

    def find_or_initialize_venue
      if params[:event] && params[:event][:venue_id].present?
        Venue.find(params[:event][:venue_id]).progenitor
      else
        Venue.find_or_initialize_by_title(params[:venue_name]).progenitor
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

