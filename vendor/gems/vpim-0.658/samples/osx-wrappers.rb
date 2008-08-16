# OSX wrapper methods.
#
# The OSX classes are mirrored fairly directly into ruby by ruby/cocoa. Too
# directly for ease, this is a start at convenient ruby APIs on top of the low-level cocoa
# methods.

=begin

Ideas for things to add:

+ each for the addressbook

+ ABRecord#[]  <- valueForProperty

+ [] and each for NSCFArray (which is actually an instance of OCObject)

+ [] and each for NSCFDictionary (which is actually an instance of OCObject)

+ Can I add methods to OCObject, and have them implement themselves based on the the 'class'?

+ ABMultiValue#[index]

if index
  
is a :token, then its the identifier,
is a string, its a label
is a number, its an array index

return a Struct, so you can do

  mvalue["work"].value

=end

require 'osx/addressbook'

# put into osx/ocobject?
module OSX
  # When an NSData object is returned by an objective/c API (such as
  # ABPerson.vCardRepresentation, I actually get a OCObject back, who's class
  # instance points to either a NSData, or a related class.
  #
  # This is a convenience method to get the NSData data back as a ruby string.
  # Is it the right place to put this?
  class OCObject
    def bytes
      s = ' ' * length
      getBytes(s)
      s
    end
  end
end

# put into osx/abperson?
module OSX
  class ABPerson
    def vCard
      card = self.vCardRepresentation.bytes

      # The card representation appears to be either ASCII, or UCS-2. If its
      # UCS-2, then the first byte will be 0, so check for this, and convert
      # if necessary.
      #
      # We know it's 0, because the first character in a vCard must be the 'B'
      # of "BEGIN:VCARD", and in UCS-2 all ascii are encoded as a 0 byte
      # followed by the ASCII byte, UNICODE is great.
      if card[0] == 0
        nsstring = OSX::NSString.alloc.initWithCharacters(card, :length, card.size/2)
        card = nsstring.UTF8String

        # TODO: is nsstring.UTF8String == nsstring.to_s  ?
      end
      card
    end
  end
end

# put into osx/group?
module OSX
  class ABGroup
    def name
      self.valueForProperty(OSX::kABGroupNameProperty).to_s
    end
  end
end

