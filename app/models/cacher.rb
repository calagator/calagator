require 'fileutils'

# = Cacher
#
# Provides caching related methods.
class Cacher
  # Returns a cache key for the day, e.g. "20080730". It's used primarily by #cache calls in views. The optional +request+ object can be used to provide a cache prefix so that the caching is specific to a particular hostname.
  def self.daily_key_for(name, request=nil)
    return "#{request.ergo{headers['HTTP_HOST'].ergo{to_s+'/'}}}#{name}@#{Time.now.strftime('%Y%m%d')}"
  end

  # Expires all cached data.
  def self.expire_all
    unless Rails.cache.cache_path.include?(RAILS_ROOT+"/tmp/cache/"+RAILS_ENV)
      raise ArgumentError, "Invalid cache_path: #{Rails.cache.cache_path}"
    end
    nodes = Dir["#{Rails.cache.cache_path}/**"]
    unless nodes.blank?
      RAILS_DEFAULT_LOGGER.info("Cacher.expire_all: #{nodes.inspect}")
      FileUtils.rm_rf(nodes)
    end
  end
end
