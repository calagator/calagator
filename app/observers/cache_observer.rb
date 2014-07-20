# = CacheObserver
#
# Expires caches.
class CacheObserver < ActiveRecord::Observer
  observe :event, :venue

  #---[ Unique methods ]--------------------------------------------------

  # Returns a cache key string for the day, e.g. "20080730". It's used
  # primarily by the #cache_if calls in views. The optional +request+ object
  # provides a HTTP_HOST so that caching can be done for a particular hostname.
  def self.daily_key_for(name, request=nil)
    return "#{name}@#{Time.now.strftime('%Y%m%d')}"
  end

  # Expires all cached data.
  def self.expire_all
    Rails.logger.info "CacheObserver::expire_all: invoked"
    Rails.cache.clear
  end

  #---[ Triggers ]--------------------------------------------------------

  def after_save(record)
    Rails.logger.info "CacheObserver#after_save: invoked"
    self.class.expire_all
  end

  def after_destroy(record)
    Rails.logger.info "CacheObserver#after_destroy: invoked"
    self.class.expire_all
  end
end
