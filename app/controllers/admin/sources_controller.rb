class Admin::SourcesController < ApplicationController
  layout "admin"
  active_scaffold :source do |config|
    config.list.columns = [:url, :title, :imported_at]
    config.columns.exclude :events, :venues, :updates
  end
end
