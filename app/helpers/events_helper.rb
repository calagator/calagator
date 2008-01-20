module EventsHelper
  def url_column(record)
    record.url.blank? ? nil : link_to("Link", record.url)
  end
end
