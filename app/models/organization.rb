class Organization < ActiveRecord::Base
  has_many :events # we might want :dependent => :destroy later

  # Validations
  validates_presence_of :name

  include ValidatesBlacklistOnMixin
  validates_blacklist_on :name, :url

  validates_format_of :url,
    :with => /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/,
    :allow_blank => true,
    :allow_nil => true

end
