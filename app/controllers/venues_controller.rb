class VenuesController < ApplicationController
  active_scaffold :venues do |config|
    config.list.columns = [:title, :address, :url]
    config.columns = [:title, :address, :url, :description, :created_at, :updated_at]
  end
end
