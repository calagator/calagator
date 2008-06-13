require 'lib/db_marshal'
require 'lib/solr_marshal'
require 'lib/easy_tgz'

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

  def self.dump(filename=nil)
    self.new.dump(filename)
  end

  def self.restore(filename)
    self.new.restore(filename)
  end

  attr_accessor :filename
  attr_accessor :dump_dir
  attr_accessor :sql_filename
  attr_accessor :solr_filename

  def initialize(opts={})
    self.filename      = opts[:filename]
    self.dump_dir      = opts[:dump_dir]      || %{#{RAILS_ROOT}/tmp/dumps}
    self.sql_filename  = opts[:sql_filename]  || %{#{self.dump_dir}/current.sql}
    self.solr_filename = opts[:solr_filename] || %{#{self.dump_dir}/current.solr}
  end

  def prepare_dump_dir
    FileUtils.mkdir_p(self.dump_dir)
  end

  def filename_or_default
    self.filename || %{#{RAILS_ENV}.#{Time.now.strftime('%Y-%m-%d@%H%M%S')}.data}
  end

  def dump(filename=nil)
    target = filename || self.filename_or_default

    self.prepare_dump_dir
    DbMarshal.dump(self.sql_filename)
    SolrMarshal.dump(self.solr_filename)

    EasyTgz.create(target) do |t|
      t.add :filename => self.sql_filename
      t.add :filename => self.solr_filename
    end

    return target
  end

  def restore(filename=nil)
    target = filename || self.filename
    raise ArgumentError, "No filename specified" unless target

    self.prepare_dump_dir
    EasyTgz.extract(filename, dump_dir)

    DbMarshal.restore(self.sql_filename)
    SolrMarshal.restore(self.solr_filename)

    return true
  end
end
