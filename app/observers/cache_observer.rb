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
    return "#{request.ergo{headers['HTTP_HOST'].ergo{to_s+'/'}}}#{name}@#{Time.now.strftime('%Y%m%d')}"
  end

  # Expires all cached data.
  def self.expire_all
    logit "invoked"
    Rails.cache.delete_matched(//)
  end

  #---[ Triggers ]--------------------------------------------------------

  def after_save(record)
    logit "invoked"
    self.class.expire_all
  end

  def after_destroy(record)
    logit "invoked"
    self.class.expire_all
  end
end
