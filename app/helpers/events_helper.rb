module EventsHelper
  def url_column(record)
    link_to truncate(record.url, 60), record.url
  end
end
