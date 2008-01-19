class EventsController < ApplicationController
  active_scaffold :event do |config|
    config.list.columns = [:title, :description, :start_time, :location, :url]
  end
end
