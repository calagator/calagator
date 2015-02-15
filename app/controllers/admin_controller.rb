class AdminController < ApplicationController
  http_basic_authenticate_with :name => SECRETS.admin_username, :password => SECRETS.admin_password, :if => Proc.new { SECRETS.admin_username && SECRETS.admin_password }

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
