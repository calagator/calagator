# = ValidatesBlacklistOnMixin
#
# A naively simple mixin that blacklists content in ActiveRecord::Base objects.
#
# == Usage
#
# Let's say that your applications lets people post messages, but don't want
# them using the word "viagra" in posts as a naively simple way of preventing
# spam.
#
# You'd first create a RAILS_ROOT/config/blacklist.txt file with a line like:
#   \bviagrab\b
#
# And then you'd include the blacklisting feature into your Message class like:
#
#   class Message < ActiveRecord::Base
#     include ValidatesBlacklistOnMixin
#     validates_blacklist_on :title, :content
#   end
#
# Now including the word "viagra" in your record's values will fail:
#
#   message = Message.new(:title => "foo viagra bar")
#   message.valid? # => false
module ValidatesBlacklistOnMixin
  BLACKLIST_DEFAULT_MESSAGE = "contains blacklisted content"

  def self.included(mixee)
    mixee.extend ClassMethods
  end

  module ClassMethods
    # Validates that specified attributs do not contain blacklisted contents,
    # e.g., the names of medications frequently advertised by spammers.
    #
    # Options:
    #   * :patterns => Array of regular expressions that will be matched
    #     against the given attribute contents and any matches will cause the
    #     record to be marked invalid.
    #   * :blacklist => Reads an array of blacklisted regular expressions from
    #     a filename.
    #   * :message => Error message to use on invalid records.
    #
    # If no :patterns or :blacklist is given, patterns are read from:
    # RAILS_ROOT/config/blacklist.txt
    def validates_blacklist_on(*attrs)
      before_validation {|record| record.send(:_validate_blacklist_on_record, *attrs)}
    end

    # Return array of regular expressions to be used for blacklisting. If a
    # +filename+ is given, it will be read. If the filename doesn't have an
    # explicit path, it'll be assumed to be in the RAILS_ROOT/config directory.
    # If no filename is specified, the RAILS_ROOT/config/blacklist.txt file
    # will be used.
    def _get_blacklist_patterns_from(filename=nil)
      filename ||= "blacklist.txt"
      filename = "#{RAILS_ROOT}/config/#{filename}" unless filename.match(/[\/\\]/)
      return File.read(filename).map{|line| Regexp.new(line.strip, Regexp::IGNORECASE)}
    end
  end

protected

  def _validate_blacklist_on_record(*attrs)
    opts = { :message => ValidatesBlacklistOnMixin::BLACKLIST_DEFAULT_MESSAGE }
    opts.update(attrs.extract_options!.symbolize_keys)
    patterns = opts[:patterns] || self.class._get_blacklist_patterns_from(opts[:blacklist])
    is_valid = true
    attrs.each do |attr|
      value = self.send(attr).to_s
      next if value.blank?
      patterns.each do |pattern|
        if value.match(pattern)
          self.errors.add(attr, opts[:message])
          is_valid = false
        end
      end
    end
    return is_valid
  end
end
