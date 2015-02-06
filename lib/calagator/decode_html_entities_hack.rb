# = DecodeHtmlEntitiesHack
#
# Loofah encodes HTML entities in every string that gets passed through it.
# This includes things like the friendly ampersand which we don't want to be HTML
# encoded in our database, so we need to decode the things that it changes.
#
# This should be included in models that use xss_foliate somewhere _after_ the xss_folidate call.
#
# This is, as the name of the module suggests, a giant hack. At some point, it should
# be removed after the issue is resolved in the underlying library:
# https://github.com/flavorjones/loofah/issues/20#issuecomment-1751538
#
# Warning: this effectively renders loofah's "escape" scrubbing mode useless by
# undoing everything it does. Don't use that mode.
#
module Calagator

module DecodeHtmlEntitiesHack
  def self.included(base)
    base.set_callback(:validate, :before, :decode_html_entities)
  end

  def decode_html_entities
    self.attributes.each do |field, value|
      decoded_content = HTMLEntities.new.decode(value)
      if decoded_content.present? && !(decoded_content == value)
        self.send("#{field}=", decoded_content)
      end
    end
  end
end

end
