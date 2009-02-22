require 'yaml'
require 'erb'
require 'ostruct'

require 'rubygems'
require 'activesupport'

# = SecretsReader
#
# Reads secrets from an ERB-parsed YAML file and returns an OpenStruct object.
#
# Examples:
#   # Read from default "config/secrets.yml" and "config/secrets.yml.sample" files:
#   Secrets = SecretsReader.read
#
#   # Read a specific file:
#   Secrets = SecretsReader.read("myfile.yml") #
#
class SecretsReader
  # Return an OpenStruct object with secret information. The secrets are read
  # from an ERB-parsed YAML file.
  #
  # Arguments:
  # * Filename to read secrets from. Optional, if not given will try
  #   "config/secret.yml" and "config/secret.yml.sample".
  #
  # Options:
  # * :verbose => Print status to screen on error. Defaults to true.
  def self.read(*args)
    opts = args.extract_options!
    verbose = opts[:verbose] != false
    given_file = args.first

    normal_file = "config/secrets.yml"
    sample_file = "config/secrets.yml.sample"
    rails_root = RAILS_ROOT rescue File.dirname(File.dirname(__FILE__))

    message = "** SecretsReader - "
    error = false

    if object = self.filename_to_ostruct(given_file)
      message << "loaded '#{given_file}'"
    elsif object = self.filename_to_ostruct(File.join(rails_root, normal_file))
      message << "loaded '#{normal_file}'"
    elsif object = self.filename_to_ostruct(File.join(rails_root, sample_file))
      message << "WARNING! Using insecure '#{sample_file}' settings, see README.txt"
      error = true
    else
      raise Errno::ENOENT, "Couldn't find '#{normal_file}'"
    end

    puts message if error
    RAILS_DEFAULT_LOGGER.info(message) rescue nil

    return object
  end

  # Return an OpenStruct object by reading the +filename+ and parsing it with ERB and YAML.
  def self.filename_to_ostruct(filename)
    return OpenStruct.new(YAML.load(ERB.new(File.read(filename)).result)) rescue nil
  end
end
