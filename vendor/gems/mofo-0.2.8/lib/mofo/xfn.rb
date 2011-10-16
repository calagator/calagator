$:.unshift 'lib'
require 'microformat'

class XFN < Microformat
  class Link < OpenStruct
    def initialize(*args)
      super
      def relation.has?(value)
        is_a?(Array) ? include?(value) : self == value
      end
    end

    def to_html
      %[<a href="#{link}" rel="#{Array(relation) * ' '}">#{name}</a>]
    end

    def to_s
      link
    end
  end

  attr_accessor :links

  def self.find_occurences(doc)
    raise NotImplementedError, "XFN not supported yet. What's the Nokogiri equivalent of Hpricot::Doc?"
    case doc
    when Nokogiri::XML::Element then @occurences = XFN.new(doc)
    else @occurences
    end
  end

  class << self
    alias :find_first :find_occurences
    alias :find_every :find_occurences
  end

  def initialize(doc)
    @links = doc.search("a[@rel]").map do |rl|
      relation = rl[:rel].include?(' ') ? rl[:rel].split(' ') : rl[:rel]
      Link.new(:name => rl.inner_html, :link => rl[:href], :relation => relation)
    end
  end

  def relations
    @relations ||= @links.map { |l| l.relation }
  end

  def [](*rels)
    @links.select do |link|
      relation = link.relation
      relation.respond_to?(:all?) && rels.all? { |rel| relation.include? rel }
    end.first_or_self
  end

  def method_missing(method, *args, &block)
    method = method.to_s
    if (rels = method.split(/_and_/)).size > 1
      self[*rels]
    elsif @links.class.public_instance_methods.include? method
      @links.send(method, *args, &block)
    else
      check = args.first == true ? :== : :has?
      @links.select { |link| link.relation.send(check, method) }.first_or_self
    end
  end
end
