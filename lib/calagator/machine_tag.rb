# We're extending ActsAsTaggableOn's Tag model to include support for machine tags and such.
module Calagator

class MachineTag < Struct.new(:name)
  module TagExtensions
    def machine_tag
      MachineTag.new(name).to_hash
    end
  end

  def self.configure
    yield self
  end

  cattr_accessor(:urls) { Hash.new }
  cattr_accessor(:venue_predicates) { Array.new }
  cattr_accessor(:defunct_namespaces) { Array.new }
  cattr_accessor(:site_root_url) { "http://example.com/" }

  # Return a machine tag hash for this tag, or an empty hash if this isn't a
  # machine tag. The hash will always contain :namespace, :predicate and :value
  # key-value pairs. It may also contain an :url if one is known.
  #
  # Machine tags describe references to remote resources. For example, a
  # Calagator event imported from an Meetup event may have a machine
  # linking it back to the Meetup event.
  #
  # Example:
  #   # A tag named "meetup:group=1234" will produce this machine tag:
  #   tag.machine_tag == {
  #     :namespace => "meetup",
  #     :predicate => "group",
  #     :value     => "1234",
  #     :url       => "http://www.meetup.com/1234",
  def to_hash
    return {} unless matches
    {
      namespace: namespace,
      predicate: predicate,
      value:     value,
      url:       url,
    }
  end

  def venue?
    venue_predicates.include? predicate
  end

  private

  # Regular expression for parsing machine tags
  MACHINE_TAG_PATTERN = /(?<namespace>[^:]+):(?<predicate>[^=]+)=(?<value>.+)/

  def matches
    name.match(MACHINE_TAG_PATTERN)
  end

  def namespace
    matches[:namespace]
  end

  def predicate
    matches[:predicate]
  end

  def value
    matches[:value]
  end

  def url
    return unless machine_tag = urls[namespace]
    return unless url_template = machine_tag[predicate]
    url = sprintf(url_template, value)
    url = "#{site_root_url}defunct?url=https://web.archive.org/web/#{archive_date}/#{url}" if defunct?
    url
  end

  def defunct?
    defunct_namespaces.include? namespace
  end

  def archive_date
    (venue_date || event_date).strftime("%Y%m%d")
  end

  def venue_date
    Venue.tagged_with(name).limit(1).pluck(:created_at).first
  end

  def event_date
    Event.tagged_with(name).limit(1).pluck(:start_time).first
  end
end

end
