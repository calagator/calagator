# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'atom'
require 'atom/xml/parser'
require 'atom/version'
require 'xml/libxml'
require 'uri'
require 'net/http'

module Atom
  module Pub
    class NotSupported < StandardError; end
    class ProtocolError < StandardError
      attr_reader :response
      def initialize(response)
        @response = response
      end
    end
    
    class Service
      include Atom::Xml::Parseable
      namespace Atom::Pub::NAMESPACE
      elements :workspaces
      loadable! do |reader, message, severity, base, line|
        if severity == XML::Reader::SEVERITY_ERROR
          raise ParseError, "#{message} at #{line}"
        end
      end
      
      def initialize(xml = nil)
        @workspaces = []

        if xml
          begin
            if next_node_is?(xml, 'service', Atom::Pub::NAMESPACE)
              xml.read
              parse(xml)
            else
              raise ArgumentError, "XML document was missing atom:service"        
            end
          ensure
            xml.close
          end
        end
        
        yield(self) if block_given?        
      end
    end
    
    class Categories < DelegateClass(Array)
      include Atom::Xml::Parseable
      elements :categories, :class => Atom::Category
      
      def initialize(o)
        super([])
        o.read
        parse(o)
      end

      remove_method :categories
      def categories; self; end
    end
    
    class Workspace
      include Atom::Xml::Parseable
      element :title, :class => Content, :namespace => Atom::NAMESPACE
      elements :collections
      
      def initialize(o = nil)
        @collections = []
        
        case o
        when XML::Reader
          o.read
          parse(o)
        when Hash
          o.each do |k, v|
            self.send("#{k}=".to_sym, v)
          end
        end
        
        yield(self) if block_given?
      end
    end
    
    class Collection
      include Atom::Xml::Parseable
      attribute :href
      element :title, :class => Content, :namespace => Atom::NAMESPACE
      element :categories, :class => Categories
      elements :accepts, :content_only => true
      
      def initialize(o = nil)
        @accepts = []
        case o
        when XML::Reader
          # do it once to get the attributes
          parse(o, :once => true)
          # now step into the element and the sub tree
          o.read
          parse(o)
        when Hash
          o.each do |k, v|
            self.send("#{k}=", v)
          end  
        end
        
        yield(self) if block_given?
      end
      
      def feed
        if href
          Atom::Feed.load_feed(URI.parse(href))
        end
      end
      
      def publish(entry)
        uri = URI.parse(href)
        response = nil
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.post(uri.path, entry.to_xml.to_s, headers)
        end
        
        case response
        when Net::HTTPCreated
          published = begin
            Atom::Entry.load_entry(response.body)
          rescue Atom::ParseError
            entry
          end
        
          if response['Location']
            if published.edit_link
              published.edit_link.href = response['Location']
            else
              published.links << Atom::Link.new(:rel => 'edit', :href => response['Location'])
            end
          end
        
          published
        else
          raise Atom::Pub::ProtocolError, response
        end
      end
      
      private
      def headers
        {'Accept' => 'application/atom+xml',
         'Content-Type' => 'application/atom+xml;type=entry',
         'User-Agent' => "rAtom #{Atom::VERSION::STRING}"
         }
      end
    end
  end
  
  class Entry    
    def save!
      if edit = edit_link
        uri = URI.parse(edit.href)
        response = nil
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.put(uri.path, self.to_xml, headers)
        end
        
        case response
        when Net::HTTPSuccess
        else
          raise Atom::Pub::ProtocolError, response
        end
      else
        raise Atom::Pub::NotSupported, "Entry does not have an edit link"
      end
    end
    
    def destroy!
      if edit = edit_link
        uri = URI.parse(edit.href)
        response = nil
        Net::HTTP.start(uri.host, uri.port) do |http|
          response = http.delete(uri.path, {'Accept' => 'application/atom+xml', 'User-Agent' => "rAtom #{Atom::VERSION::STRING}"})
        end
        
        case response
        when Net::HTTPSuccess
        else
          raise Atom::Pub::ProtocolError, response
        end
      else
        raise Atom::Pub::NotSupported, "Entry does not have an edit link"
      end
    end
    
    private
    def headers
      {'Accept' => 'application/atom+xml',
       'Content-Type' => 'application/atom+xml;type=entry',
       'User-Agent' => "rAtom #{Atom::VERSION::STRING}"
       }
    end    
  end
end
