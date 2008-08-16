require 'vpim/vcard'

card = Vpim::Vcard::Maker.make2 do |maker|
  maker.add_name do |name|
    name.prefix = 'Dr.'
    name.given = 'Jimmy'
    name.family = 'Death'
  end

  maker.add_addr do |addr|
    addr.preferred = true
    addr.location = 'work'
    addr.street = '12 Last Row, 13th Section'
    addr.locality = 'City of Lost Children'
    addr.country = 'Cinema'
  end

  maker.add_addr do |addr|
    addr.location = [ 'home', 'zoo' ]
    addr.delivery = [ 'snail', 'stork', 'camel' ]
    addr.street = '12 Last Row, 13th Section'
    addr.locality = 'City of Lost Children'
    addr.country = 'Cinema'
  end

  maker.nickname = "The Good Doctor"

  maker.birthday = Date.today

  maker.add_photo do |photo|
    photo.link = 'http://example.com/image.png'
  end

  maker.add_photo do |photo|
    photo.image = "File.open('drdeath.jpg').read # a fake string, real data is too large :-)"
    photo.type = 'jpeg'
  end

  maker.add_tel('416 123 1111')

  maker.add_tel('416 123 2222') { |t| t.location = 'home'; t.preferred = true }

  maker.add_impp('joe') do |impp|
    impp.preferred = 'yes'
    impp.location = 'mobile'
  end

  maker.add_x_aim('example') do |xaim|
    xaim.location = 'row12'
  end

  maker.add_tel('416-123-3333') do |tel|
    tel.location = 'work'
    tel.capability = 'fax'
  end

  maker.add_email('drdeath@work.com') { |e| e.location = 'work' }

  maker.add_email('drdeath@home.net') { |e| e.preferred = 'yes' }

end

puts card

