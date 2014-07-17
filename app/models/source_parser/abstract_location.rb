class SourceParser
  class AbstractLocation < Struct.new(
    :title,
    :description,

    :address,

    :street_address,
    :locality,
    :region,
    :postal_code,
    :country,

    :latitude,
    :longitude,

    :url,
    :email,
    :telephone,
    :tags)

    def initialize(*args)
      super
      self.tags ||= []
    end
  end
end
