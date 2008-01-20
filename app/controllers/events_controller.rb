class EventsController < ApplicationController
  active_scaffold :event do |config|
    config.list.columns = [:url, :title, :description, :start_time, :venue]
    config.columns = [:url, :title, :description, :start_time, :venue, :created_at, :updated_at]
  end
end
