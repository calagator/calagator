module Calagator

class AdminController < Calagator::ApplicationController
  require_admin

  def index
  end

  def events
    @events = Event.future
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
    redirect_to :action => :events
  end

end

end
