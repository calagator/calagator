class VenuesController < ApplicationController
  active_scaffold :venues do |config|
    config.list.columns = [:title, :description, :address, :url]
  end
end
