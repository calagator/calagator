require 'vpim/vcard'

ORIGINAL =<<'---'
BEGIN:VCARD
VERSION:3.0
FN:Jimmy Death
N:Death;Jimmy;;Dr.;
TEL:+416 123 1111
TEL;type=home,pref:+416 123 2222
TEL;type=work,fax:+416+123+3333
EMAIL;type=work:drdeath@work.com
EMAIL;type=pref:drdeath@home.net
NOTE:Do not call.
END:VCARD
---

original = Vpim::Vcard.decode(ORIGINAL).first

puts original

modified = Vpim::Vcard::Maker.make2 do |maker|
  # Set the fullname field to use family-given name order.
  maker.name do |n|
    n.fullname = "#{original.name.family} #{original.name.given}"
  end

  # Copy original fields, with some changes:
  # - set only work email addresses and telephone numbers to be preferred.
  # - don't copy notes
  maker.copy(original) do |field|
    if field.name? 'EMAIL'
      field = field.copy
      field.pref = field.type? 'work'
    end
    if field.name? 'TEL'
      field = field.copy
      field.pref = field.type? 'work'
    end
    if field.name? 'NOTE'
      field = nil
    end
    field
  end
end

puts '---'
puts modified

Vpim::Vcard::Maker.make2(modified) do |maker|
  maker.nickname = "Your Last Friend"
end

puts '---'
puts modified

