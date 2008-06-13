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
  require 'zlib'
  require 'rubygems'
  require 'archive/tar/minitar' # gem install archive-tar-minitar
  require 'lib/easy_tgz'

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
    self.index_dir = opts[:index_dir] || %{#{RAILS_ROOT}/vendor/plugins/acts_as_solr/solr/solr/data/#{RAILS_ENV}/index}
  end

  def filename_or_default
    self.filename || %{#{RAILS_ENV}.#{Time.now.strftime('%Y-%m-%d@%H%M%S')}.solr}
  end

  def dump(filename=nil)
    target = filename || self.filename_or_default

    EasyTgz.create(target) do |easytgz|
      Dir["#{self.index_dir}/*"].each do |path|
        easytgz.add :filename => path, :as => File.basename(path)
      end
    end

    return target
  end

  def restore(filename=nil)
    target = (filename || self.filename) or raise ArgumentError, "No filename specified"
    EasyTgz.extract(target, self.index_dir)
    return true
  end
end
