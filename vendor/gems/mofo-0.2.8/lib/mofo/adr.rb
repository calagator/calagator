# => http://microformats.org/wiki/adr
require 'microformat'

class Adr < Microformat
  one :post_office_box, :extended_address, :street_address,
      :locality, :region, :postal_code, :country_name, :value

  many :type
end
