class EventsController < ApplicationController
  active_scaffold :event do |config|
    config.list.sorting = {:start_time => :desc}
    config.list.columns = [:url, :title, :description, :start_time, :venue]
    config.columns = [:url, :title, :description, :start_time, :venue, :created_at, :updated_at]
    config.show.link.inline = false
  end
end
