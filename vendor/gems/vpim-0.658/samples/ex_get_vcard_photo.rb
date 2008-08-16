#!/usr/bin/ruby -w

require 'vpim/vcard'

vcf = open(ARGV[0] || 'data/vcf/Sam Roberts.vcf')

card = Vpim::Vcard.decode(vcf).first

card.photos.each_with_index do |photo, i|
  file = "_photo_#{i}."

  if photo.format
    file += photo.format.gsub('/', '_')
  else
    # You are your own if PHOTO doesn't include a format. AddressBook.app
    # exports TIFF, for example, but doesn't specify that.
    file += 'tiff'
  end

  open(file, 'w').write photo.to_s
end

