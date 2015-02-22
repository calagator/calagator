class AdminController < ApplicationController
  before_filter :authenticate
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

  private

  def authenticate
    authed = authenticate_with_http_basic do |u, p|
      u == SECRETS.admin_username && p == SECRETS.admin_password
    end
    if authed
      session[:admin] = true
      @current_admin  = true
    else
      request_http_basic_authentication
    end
  end
end
