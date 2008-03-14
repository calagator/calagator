class Admin::EventsController < ApplicationController
  layout "admin"
  active_scaffold :event do |config|
    config.list.columns = [:url, :title, :description, :start_time, :venue]
    config.columns = [:url, :title, :description, :start_time, :venue, :created_at, :updated_at]
    config.show.link.inline = false
    #config.update.link.inline = false
  end
end
