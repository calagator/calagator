# Standard libraries
require 'stringio'
require 'zlib'

# 3rd party libraries
require 'rubygems'
require 'archive/tar/minitar' # gem install archive-tar-minitar

# = EasyTgz
#
# An easy-to-use library for creating and extracting tar.gz (tgz) files.
#
# == Creating
#
#   EasyTgz.create("myarchive.tgz") do |t|
#     t.add(:filename => "myfile")
#     t.add(:filename => "otherfile", :as => "newname")
#   end
#
# == Extracting
#
#  EasyTgz.extract("myarchive.tgz", "target_directory")
class EasyTgz
  class Reader
    # Extract archive +filename+ into +target_directory+.
    def self.extract(filename, target_directory, &block)
      # TODO provide a way to extract individual items via block
      tgz = Zlib::GzipReader.new(File.open(filename, 'rb'))
      Archive::Tar::Minitar.unpack(tgz, target_directory)
      return true
    end
  end

  class Writer
    # Create archive +filename+. If a block is given, yields an instance of the
    # Writer that you can add files to and automatically closes the handles.
    # Without a block, simply returns the opened instance.
    #
    # See EasyTgz::Writer.add for how to add entries to the archive.
    def self.create(filename, &block)
      instance = self.new(filename)
      if block
        block.call(instance)
        instance.close
        return File.size(filename)
      else
        return instance
      end
    end

    # Instantiate a Writer for an archive +filename+.
    def initialize(filename)
      @filename = filename
      @minitar = \
        Archive::Tar::Minitar::Output.new(
          Zlib::GzipWriter.new(
            File.open(@filename, "w+")))
    end

    # Add the entry to the archive.
    #
    # Options:
    # * :stats => Hash that can contain :size, :mtime and :mode elements
    #   describing the entry. The :mtime and :mode elements have sensible
    #   defaults, but the :size must be specified if you're adding a handle.
    # * :as => Optional string to use as the filename in the archive entry,
    #   although the source will still be read as normal.
    #
    # Also add one of the following to specify the source:
    # * :filename => Path of the filename to add.
    # * :string => String contents to add as entry to archive. You must provide
    #   the :as option.
    # * :handle => Handle to read and add as entry to archive. You must provide
    #   the :as option and the :size for the :stats unless the handle is either
    #   a File or StringIO instance.
    #
    # Example:
    #
    #   # Create a new archive
    #   EasyTgz.create("myarchive.tgz") do |t|
    #     # Add the "myfile" filename
    #     t.add :filename => "myfile"
    #
    #     # Add the string "foo" to the archive as the entry "bar"
    #     t.add :string => "foo", :as => "bar"
    #
    #     # Add the contents of handle "myfile" as the entry "baz"
    #     t.add :handle => myfile, :as => "baz"
    #
    #     # Add the contents of handle "mystery" as the entry "qux" and limit
    #     # it to 42 bytes
    #     t.add :handle => mystery, :as => "qux", :stats => {:size => 42}
    #   end
    def add(opts)
      stats = opts[:stats] || {}
      source = nil
      as = opts[:as]

      begin
        if opts[:filename]
          as ||= opts[:filename]
          source = File.open(opts[:filename])
          stat = File.stat(opts[:filename])
          stats[:mode]  ||= stat.mode
          stats[:mtime] ||= stat.mtime
          stats[:size]  ||= stat.size
        elsif opts[:handle]
          source = opts[:handle]
          stats[:size] ||= \
            case source
            when File     then File.size(source)
            when StringIO then source.size
            end
        elsif opts[:string]
          source = StringIO.new(opts[:string])
          stats[:size] ||= opts[:string].size
        else
          raise ArgumentError, "No source specified, must have either a :filename, :handle or :string"
        end

        stats[:mtime] ||= Time.now
        stats[:mode]  ||= 0700

        minitar_opts = stats.merge({})
        @minitar.tar.add_file_simple(as, minitar_opts) do |adder|
          adder.write(source.read)
        end
      rescue Exception => e
        self.close
        File.unlink(@filename)
        raise e
      ensure
        source.close if source && !source.closed?
      end

      return true
    end

    # Close the archive handle if needed.
    def close
      @minitar.close if @minitar
    end
  end

  # Create a new archive. See EasyTgz::Writer.create for details.
  def self.create(*args, &block)
    ::EasyTgz::Writer.create(*args, &block)
  end

  # Extract an archive. see EasyTgz::Reader.extract for details.
  def self.extract(*args, &block)
    ::EasyTgz::Reader.extract(*args, &block)
  end

end
