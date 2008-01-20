class EventsController < ApplicationController
  active_scaffold :event do |config|
    config.list.columns = [:title, :description, :start_time, :venue, :url]
    config.columns = [:title, :description, :start_time, :venue, :url, :created_at, :updated_at]
  end
end
