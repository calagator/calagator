module EventsHelper
  def url_column(record)
    link_to "Link", record.url
  end
end
