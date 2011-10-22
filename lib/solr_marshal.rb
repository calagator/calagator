# = SolrMarshal
#
# A library for dumping and restoring Solr index files.
#
# == Dumping
#
#   # Automatically name the dump
#   SolrMarshal.dump
#
#   # ...or give it a specific name
#   SolrMarshal.dump("myindex.solr")
#
# == Restoring
#
#   SolrMarshal.restore("myindex.solr")
#
# == Advanced operations
#
#   # Use a non-default +index_dir+ for dump
#   SolrMarshal.new(:index_dir => "solr/data").dump("myindex.solr")
#
#   # ...or a restore
#   SolrMarshal.new(:index_dir => "solr/data").restore("myindex.solr")
class SolrMarshal
  require 'fileutils'
  require 'rubygems'
  require 'zip/zip' # gem install rubyzip

  # Directory with Solr indices
  attr_accessor :index_dir

  # Filename of Solr dump
  attr_accessor :filename

  def self.dump(filename=nil, opts={})
    self.new(opts.merge({:filename => filename})).dump
  end

  def self.restore(filename, opts={})
    self.new(opts.merge({:filename => filename})).restore
  end

  def initialize(opts={})
    self.filename  = opts[:filename]
    self.index_dir = opts[:index_dir] || Rails.root.join('vendor','plugins','acts_as_solr','solr','solr','data',Rails.env,'index')
  end

  def filename_or_default
    self.filename || %{#{Rails.env}.#{Time.now.strftime('%Y-%m-%d@%H%M%S')}.solr}
  end

  def dump(filename=nil)
    target = filename || self.filename_or_default

    # NOTE ZipOutputStream.new fails if given a block
    # NOTE File.read fails if given a "rb" option
    zos = Zip::ZipOutputStream.new(target)
    Dir["#{self.index_dir}/*"].each do |path|
      zos.put_next_entry(File.basename(path))
      File.open(path, "rb"){|reader| zos.write(reader.read)}
    end
    zos.close

    return target
  end

  def restore(filename=nil)
    target = (filename || self.filename) or raise ArgumentError, "No filename specified"

    # NOTE ZipInputStream.new fails if given a block
    # NOTE File.read fails if given a "wb+" option
    zis = Zip::ZipInputStream.new(target)
    while entry = zis.get_next_entry
      FileUtils.mkdir_p(self.index_dir) rescue nil
      File.open("#{self.index_dir}/#{entry.name}", "wb+"){|h| h.write(zis.read)}
    end
    zis.close
    
    return true
  end
end
