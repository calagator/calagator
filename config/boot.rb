require 'rubygems'

# Monkeypatch to make Regexp::escape support Pathnames. This is a bug present in Rubygems 1.8.10 and Rails 3.0.10.
require 'pathname'
class Regexp
  class << self
    alias_method :escape_without_pathname, :escape
    def escape(*args)
      self.escape_without_pathname(* args.first.kind_of?(Pathname) ? [args.first.to_s, *args[1..-1]] : args)
    end
  end
end

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
