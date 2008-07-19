class SourceParser
  AbstractLocation = Struct.new(
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
    :telephone)
end
