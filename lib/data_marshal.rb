# = DataMarshal
#
# Library for marshalling all Calagator data. Useful for packaging up the
# entire production server's state and downloading it to a development
# instance.
#
# == Dump
#
#   DataMarshal.dump "mydata.data"
#
# == Restore
#
#   DataMarshal.restore "mydata.data"
class DataMarshal
  require 'fileutils'
  require 'lib/db_marshal'
  require 'lib/solr_marshal'
  require 'zip/zip' # gem install rubyzip

  def self.dump(filename=nil)
    self.new.dump(filename)
  end

  def self.dump_cached(filename=nil)
    self.new.dump_cached(filename)
  end

  def self.restore(filename)
    self.new.restore(filename)
  end

  attr_accessor :filename
  attr_accessor :dump_dir
  attr_accessor :sql_filename
  attr_accessor :solr_filename
  attr_accessor :use_cache

  def initialize(opts={})
    self.filename      = opts[:filename]
    self.dump_dir      = opts[:dump_dir]      || Rails.root.join('tmp','dumps')
    self.sql_filename  = opts[:sql_filename]  || %{#{self.dump_dir}/current.sql}
    self.solr_filename = opts[:solr_filename] || %{#{self.dump_dir}/current.solr}
    self.use_cache     = opts[:use_cache] == true
  end

  def prepare_dump_dir
    FileUtils.mkdir_p(self.dump_dir)
  end

  def filename_or_default
    self.filename || %{#{Rails.env}.#{Time.now.strftime('%Y-%m-%d@%H%M%S')}.data}
  end
  
  def dump_cached(filename=nil)
    self.use_cache = true
    return self.dump(filename)
  end

  def dump(filename=nil)
    target = filename || self.filename_or_default

    if File.exist?(target) && self.use_cache && (File.mtime(target) > (Time.now-1.minute))
      return filename
    end

    self.prepare_dump_dir
    DbMarshal.dump(self.sql_filename)
    SolrMarshal.dump(self.solr_filename)

    # NOTE ZipOutputStream.new fails if given a block
    # NOTE File.read fails if given a "rb" option
    zos = Zip::ZipOutputStream.new(target)
    zos.put_next_entry(File.basename(self.sql_filename))
    File.open(self.sql_filename, "rb"){|h| zos.write(h.read)}
    zos.put_next_entry(File.basename(self.solr_filename))
    File.open(self.solr_filename, "rb"){|h| zos.write(h.read)}
    zos.close

    return target
  end

  def restore(filename=nil)
    target = filename || self.filename
    raise ArgumentError, "No filename specified" unless target

    self.prepare_dump_dir

    # NOTE ZipInputStream.new fails if given a block
    # NOTE File.read fails if given a "wb+" option
    zis = Zip::ZipInputStream.new(target)
    while entry = zis.get_next_entry
      FileUtils.mkdir_p(self.dump_dir) rescue nil
      File.open("#{self.dump_dir}/#{entry.name}", "wb+"){|h| h.write(zis.read)}
    end
    zis.close

    DbMarshal.restore(self.sql_filename)
    SolrMarshal.restore(self.solr_filename)

    return true
  end
end
