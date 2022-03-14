# frozen_string_literal: true

# = DenylistValidator
#
# A naively simple mixin used to ban words in ActiveModel objects.
#
# == Usage
#
# Let's say that your applications lets people post messages, but don't want
# them using the word "viagra" in posts as a naively simple way of preventing
# spam.
#
# You'd first create a config/denylist.txt file with a line like:
#   \bviagrab\b
#
# And then you'd include the denylisting feature into your Message class like:
#
#   class Message < Calagator::ApplicationRecord
#     validates :title, :content, denylist: true
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
#   * denylist: Reads an array of denylisted regular expressions from
#     a filename.
#   * message: Error message to use on invalid records.
#
# If no :patterns or :denylist is given, patterns are read from:
#   * config/denylist.txt
#   * config/denylist-local.txt

class DenylistValidator < ActiveModel::EachValidator
  DENYLIST_DEFAULT_MESSAGE = 'contains denylisted content'

  def validate_each(record, attribute, value)
    if value.present? && patterns.any? { |pattern| value.match(pattern) }
      record.errors.add attribute, message
    end
  end

  private

  def message
    options.fetch(:message, DENYLIST_DEFAULT_MESSAGE)
  end

  def patterns
    @patterns ||= options.fetch(:patterns) do
      [
        Calagator.denylist_patterns,
        get_denylist_patterns_from(options.fetch(:denylist, 'denylist.txt'))
      ].flatten.compact
    end
  end

  def get_denylist_patterns_from(filename)
    unless %r{[/\\]}.match?(filename)
      filename = Rails.root.join('config', filename)
    end
    return unless File.exist?(filename)

    File.readlines(filename).map do |line|
      Regexp.new(line.strip, Regexp::IGNORECASE)
    end
  end
end
