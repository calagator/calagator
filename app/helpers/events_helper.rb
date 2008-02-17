require 'uri'

module EventsHelper
  def url_column(record)
    begin
      link = URI.parse(record.url)
      raise "Invalid url" unless link.scheme =~ /^https?$/
      link_to("Link", link.to_s)
    rescue
      nil
    end
  end

  def to_hcal_column(record)
    record.to_hcal
  end
end
