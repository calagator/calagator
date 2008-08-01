# == CLI::Command
#
# Here is an example of usage:
#
#   # General Options
#
#   module GeneralOptions
#     attr_accessor :dryrun ; alias_accessor :n, :noharm, :dryrun
#     attr_accessor :quiet  ; alias_accessor :q, :quiet
#     attr_accessor :force
#     attr_accessor :trace
#   end
#
#   # Build Subcommand
#
#   class BuildCommand < CLI::Command
#     include GeneralOptions
#
#     # metadata files
#     attr_accessor  :file     ; alias_accessor :f, :file
#     attr_accessor  :manifest ; alias_accessor :m, :manifest
#
#     def call
#       # do stuf here
#     end
#   end
#
#   # Box Master Command
#
#   class BoxCommand < CLI::Command
#     subcommand :build,     BuildCommand
#   end
#
#   BoxCommand.start
#
# == Authors
#
# * Trans
#
# == Todo
#
# * Move helpers into core.
# * Add global options to master command, or "all are master options" flag (?)
# * Add usage/help/documentation/man features (?)
#
# == Copying
#
# Copyright (c) 2005,2008 Thomas Sawyer
#
# Ruby License
#
# This module is free software. You may use, modify, and/or
# redistribute this software under the same terms as Ruby.
#
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.

require 'facets/arguments'
require 'facets/consoleutils'
require 'facets/array/not_empty'

module CLI

  # For CommandOptions, but defined external to it, so
  # that it is easy to access from user defined commands.
  # (This lookup issue should be fixed in Ruby 1.9+, and then
  # the class can be moved back into Command namespace.)

  class NoOptionError < NoMethodError
    def initialize(name, *arg)
      super("unknown option -- #{name}", name, *args)
    end
  end

  class NoCommandError < NoMethodError
    def initialize(name, *arg)
      super("unknown subcommand -- #{name}", name, *args)
    end
  end

  # Here is an example of usage:
  #
  #   # General Options
  #
  #   module GeneralOptions
  #     attr_accessor :dryrun ; alias_accessor :n, :noharm, :dryrun
  #     attr_accessor :quiet  ; alias_accessor :q, :quiet
  #     attr_accessor :force
  #     attr_accessor :trace
  #   end
  #
  #   # Build Subcommand
  #
  #   class BuildCommand < Command
  #     include GeneralOptions
  #
  #     # metadata files
  #     attr_accessor  :file     ; alias_accessor :f, :file
  #     attr_accessor  :manifest ; alias_accessor :m, :manifest
  #
  #     def call
  #       # do stuf here
  #     end
  #   end
  #
  #   # Box Master Command
  #
  #   class BoxCommand < CLI::Command
  #     subcommand :build,     BuildCommand
  #   end
  #
  #   BoxCommand.start

  class Command

    # Include this in your dispatch command if you want
    # all options to be traeted the same.

    module UniversalOptions
    end

    #

    def self.option_arity(arity_hash=nil)
      if arity_hash
        (@option_arity ||= {}).merge!(arity_hash)
      end
      @option_arity
    end

    #

    def self.start(line=nil)
      cargs = Arguments.new(line || ARGV, option_arity)
      pre = cargs.preoptions

      if instance_method(:call).arity == 0 #is_a?(SingleCommand)
        args, opts = *cargs.parameters
        new(args, opts).call
      else
        subc, argv = *cargs.subcommand
        args, opts = *argv

        if is_a?(UniversalOptions)
          new(pre, opts).call(subc, args, opts)
        else
          new(pre).call(subc, args, opts)
        end
      end
    end
  
    # Command Arguments (for single commands).

    attr :arguments

    # Command options. For dispatch commands these are the pre-options.

    attr :options

    # For dispatchers, this is a convenience method for creating subcommands.

    def self.subcommand(name, command_class, options=nil)
      options ||= {}
      if options[:no_merge]
        file, line = __FILE__, __LINE__+1
        code = %{
          def #{name}(args, opts)
            #{command_class}.new(args, opts).call
          end
        }
      else
        file, line = __FILE__, __LINE__+1
        code = %{
          def #{name}(args, opts)
            opts.merge(options)
            #{command_class}.new(args, opts).call
          end
        }
      end
      class_eval(code, file, line)
    end

    private

    #

    def initialize(*args)
      @arguments = []
      @options   = {}

      opts, args = *args.partition{ |e| Hash===e }
      #TEST("options should all be hashes"){ ! opts.all?{ |e| Hash===e }
      initialize_arguments(*args)
      initialize_options(*opts)
    end

    #

    def initialize_arguments(*arguments)
      @arguments.concat(arguments)
    end

    #

    def initialize_options(*options)
      options = options.inject{ |h,o| h.merge(o) }
      begin
        opt, val = nil, nil
        options.each do |opt, val|
          opt = opt.gsub('-','_')
          send("#{opt}=", val)
        end
      rescue NoMethodError
        option_missing(opt, val)
      end
      @options.update(options)
    end

    public

    # For a single command (ie. a subcommand) override #call with arity=0.

    def call(cmd=nil, *args)
      opts = Hash==args.last ? args.pop : {}
      #TEST("options should all be hashes"){ ! opts.all?{ |e| Hash===e }
      cmd = :default if cmd.nil?
      begin
        subcommand = method(cmd)
        parameters = [args, opts]
      rescue NameError
        subcommand = method(:command_missing)
        parameters = [cmd, args, opts]
      end
      if subcommand.arity < 0
        subcommand.call(*parameters[0..subcommand.arity])
      else
        subcommand.call(*parameters[0,subcommand.arity])
      end
    end

    #

    def default
      help
    end

    # Display help message.
    # Theone provided is just a very limited dummy routine.

    def help
      puts "USAGE #{File.basename($0)} [options]"
      puts "\nOptions:"
      options = methods.collect{ |m| m.to_s =~ /=$/ }
      options.each do |opt|
        puts "    #{opt.chomp('=')}"
      end
    end

    private

    #

    def command_missing(cmd, args, opt)
      raise NoCommandError.new(cmd, args << opt)
    end

    #

    def option_missing(opt, arg=nil)
      raise NoOptionError.new(opt)
    end

  end

  # Temporary backward compatability.
  MasterCommand = Command

end


module Console #:nodoc:
  # For backward compatibility.
  Command = CLI::Command
end


# SCRAP CODE FOR REFERENCE TO POSSIBLE ADD FUTURE FEATURES

=begin

  # We include a module here so you can define your own help
  # command and call #super to utilize this one.

  module Help

    def help
      opts = help_options
      s = ""
      s << "#{File.basename($0)}\n\n"
      unless opts.empty?
        s << "OPTIONS\n"
        s << help_options
        s << "\n"
      end
      s << "COMMANDS\n"
      s << help_commands
      puts s
    end

    private

    def help_commands
      help = self.class.help
      bufs = help.keys.collect{ |a| a.to_s.size }.max + 3
      lines = []
      help.each { |cmd, str|
        cmd = cmd.to_s
        if cmd !~ /^_/
          lines << "  " + cmd + (" " * (bufs - cmd.size)) + str
        end
      }
      lines.join("\n")
    end

    def help_options
      help = self.class.help
      bufs = help.keys.collect{ |a| a.to_s.size }.max + 3
      lines = []
      help.each { |cmd, str|
        cmd = cmd.to_s
        if cmd =~ /^_/
          lines << "  " + cmd.gsub(/_/,'-') + (" " * (bufs - cmd.size)) + str
        end
      }
      lines.join("\n")
    end

    module ClassMethods

      def help( str=nil )
        return (@help ||= {}) unless str
        @current_help = str
      end

      def method_added( meth )
        if @current_help
          @help ||= {}
          @help[meth] = @current_help
          @current_help = nil
        end
      end

    end

  end

  include Help
  extend Help::ClassMethods

=end

=begin

   # Provides a very basic usage help string.
    #
    # TODO Add support for __options.
    def usage
      str = []
      public_methods(false).sort.each do |meth|
        meth = meth.to_s
        case meth
        when /^_/
          opt = meth.sub(/^_+/, '')
          meth = method(meth)
          if meth.arity == 0
            str << (opt.size > 1 ? "[--#{opt}]" : "[-#{opt}]")
          elsif meth.arity == 1
            str << (opt.size > 1 ? "[--#{opt} value]" : "[-#{opt} value]")
          elsif meth.arity > 0
            v = []; meth.arity.times{ |i| v << 'value' + (i + 1).to_s }
            str << (opt.size > 1 ? "[--#{opt} #{v.join(' ')}]" : "[-#{opt} #{v.join(' ')}]")
          else
            str << (opt.size > 1 ? "[--#{opt} *values]" : "[-#{opt} *values]")
          end
        when /=$/
          opt = meth.chomp('=')
          str << (opt.size > 1 ? "[--#{opt} value]" : "[-#{opt} value]")
        when /!$/
          opt = meth.chomp('!')
          str << (opt.size > 1 ? "[--#{opt}]" : "[-#{opt}]")
        end
      end
      return str.join(" ")
    end

    #

    def self.usage_class(usage)
      c = Class.new(self)
      argv = Shellwords.shellwords(usage)
      argv.each_with_index do |name, i|
        if name =~ /^-/
          if argv[i+1] =~ /^[(.*?)]/
            c.class_eval %{
              attr_accessor :#{name}
            }
          else
            c.class_eval %{
              attr_reader :#{name}
              def #{name}! ; @#{name} = true ; end
            }
          end
        end
      end
      return c
    end

  end

=end
