# = JanitorObserver
#
# Expires caches through the Cacher when records are saved or destroyed.
class JanitorObserver < ActiveRecord::Observer
  observe :event, :venue

  def after_save(record)
    Cacher.expire_all
  end

  def after_destroy(record)
    Cacher.expire_all
  end
end
