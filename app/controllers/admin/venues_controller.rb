class Admin::VenuesController < ApplicationController
  layout "admin"
  active_scaffold :venues do |config|
    config.list.columns = [:title, :url]
    config.show.link.inline = false
    config.columns = [
      :title, 
      :url, 
      :description, 

      :address, 

      :street_address,
      :locality,
      :region,
      :postal_code,
      :country,

      :latitude,
      :longitude,
      
      :created_at, 
      :updated_at,
    ]
    #config.update.link.inline = false
  end
end
