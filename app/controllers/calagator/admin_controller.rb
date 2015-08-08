module Calagator

  class AdminController < Calagator::ApplicationController
    require_admin

    def index
    end

    def events
      if params[:query].blank?
        @events = Event.future
      else
        @search = Event::Search.new(params)
        @admin_query = params[:query]

        @events = @search.events

        flash[:failure] = @search.failure_message
        return redirect_to admin_events_path if @search.hard_failure?
      end

      render "calagator/admin/events"
    end

    def lock_event
      @event = Event.find(params[:event_id])

      if @event.locked?
        @event.unlock_editing!
        flash[:success] = "Unlocked event #{@event.title} (#{@event.id})"
      else
        @event.lock_editing!
        flash[:success] = "Locked event #{@event.title} (#{@event.id})"
      end
      redirect_to :action => :events, :query => params[:query]
    end

  end

end
