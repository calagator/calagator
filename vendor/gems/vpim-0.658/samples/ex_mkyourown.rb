require 'vpim/vcard'

module Vpim
  class  Vcard
    class Maker
      # Add a user-defined field, X-MY-OWN:.
      #
      # This can be done both to encode custom fields, or to add support for
      # fields that Vcard::Maker doesn't support. In the latter case, please
      # submit your methods so I can add them to vPim.
      def add_my_own(value)
        @card << Vpim::DirectoryInfo::Field.create( 'X-MY-OWN', value.to_str );
      end
    end
  end
end


card = Vpim::Vcard.create # ... or load from somewhere

Vpim::Vcard::Maker.make2(card) do |m|
  m.add_name do |n|
    n.given = 'Given'
  end
  m.add_my_own 'my value'
end

puts card

