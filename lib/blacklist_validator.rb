# = BlacklistValidator
#
# A naively simple mixin that blacklists content in ActiveModel objects.
#
# == Usage
#
# Let's say that your applications lets people post messages, but don't want
# them using the word "viagra" in posts as a naively simple way of preventing
# spam.
#
# You'd first create a config/blacklist.txt file with a line like:
#   \bviagrab\b
#
# And then you'd include the blacklisting feature into your Message class like:
#
#   class Message < ActiveRecord::Base
#     validates :title, :content, blacklist: true
#   end
#
# Now including the word "viagra" in your record's values will fail:
#
#   message = Message.new(title: "foo viagra bar")
#   message.valid? # => false
#
# Available validator options:
#   * patterns: Array of regular expressions that will be matched
#     against the given attribute contents and any matches will cause the
#     record to be marked invalid.
#   * blacklist: Reads an array of blacklisted regular expressions from
#     a filename.
#   * message: Error message to use on invalid records.
#
# If no :patterns or :blacklist is given, patterns are read from:
#   * config/blacklist.txt
#   * config/blacklist-local.txt

class BlacklistValidator < ActiveModel::EachValidator
  BLACKLIST_DEFAULT_MESSAGE = "contains blacklisted content"

  def validate_each(record, attribute, value)
    if value.present? && patterns.any? { |pattern| value.match(pattern) }
      record.errors.add attribute, message
    end
  end

  private

  def message
    options.fetch(:message, BLACKLIST_DEFAULT_MESSAGE)
  end

  def patterns
    @patterns ||= options.fetch(:patterns) do
      [
        get_blacklist_patterns_from(options.fetch(:blacklist, "blacklist.txt")),
        get_blacklist_patterns_from("blacklist-local.txt")
      ].flatten.compact
    end
  end

  def get_blacklist_patterns_from(filename)
    filename = Rails.root.join('config',filename) unless filename.match(/[\/\\]/)
    return unless File.exists?(filename)

    File.readlines(filename).map do |line|
      Regexp.new(line.strip, Regexp::IGNORECASE)
    end
  end
end
