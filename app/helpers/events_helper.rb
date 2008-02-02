module EventsHelper
  def url_column(record)
    record.url.blank? ? nil : link_to("Link", record.url)
  end
  
  def to_hcal_column(record)
    record.to_hcal
  end
end
