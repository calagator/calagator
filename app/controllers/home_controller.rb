class HomeController < ApplicationController
  def index
    @events_today = Event.find(:all, 
        :conditions => { :start_time => Time.today..(Time.today + 1.days) }, :order => 'start_time ASC', :limit => 6)
    @events_tomorrow = Event.find(:all, 
        :conditions => { :start_time => (Time.today + 1.days)..(Time.today + 2.days) }, :order => 'start_time ASC', :limit => 3)
    @events_later = Event.find(:all, 
        :conditions => { :start_time => (Time.today + 2.days)..(Time.today + 7.days) }, :order => 'start_time ASC', :limit => 3)
    
    @recently_added_events = Event.find(:all, :order => 'created_at DESC', :limit => 5)
  end
end
