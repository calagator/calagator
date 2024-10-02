---
title: Cache Observer
---
# Introduction

This document will walk you through the implementation of the Cache Observer feature.

The feature is designed to manage and expire caches for specific models in the application.

We will cover:

1. High-level overview of the Cache Observer.
2. Detailed breakdown of the code.
3. Dependencies.
4. A joke to lighten the mood.

# High-level overview

The Cache Observer is responsible for expiring caches related to the <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="8:3:3" line-data="    observe Event, Venue">`Event`</SwmToken> and <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="8:6:6" line-data="    observe Event, Venue">`Venue`</SwmToken> models. It ensures that the cache is cleared whenever these models are updated or destroyed.

# Detailed breakdown of code

## Cache observer definition

<SwmSnippet path="/app/observers/calagator/cache_observer.rb" line="3">

---

The Cache Observer is defined in <SwmPath>[app/observers/calagator/cache_observer.rb](/app/observers/calagator/cache_observer.rb)</SwmPath>. It observes the <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="8:3:3" line-data="    observe Event, Venue">`Event`</SwmToken> and <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="8:6:6" line-data="    observe Event, Venue">`Venue`</SwmToken> models.

```
# = CacheObserver
#
# Expires caches.
module Calagator
  class CacheObserver < ActiveRecord::Observer
    observe Event, Venue

    #---[ Unique methods ]--------------------------------------------------
```

---

</SwmSnippet>

## Generating a daily cache key

<SwmSnippet path="/app/observers/calagator/cache_observer.rb" line="11">

---

The <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="15:5:5" line-data="    def self.daily_key_for(name, _request = nil)">`daily_key_for`</SwmToken> method generates a cache key string for the current day. This key is used primarily in view caching.

```

    # Returns a cache key string for the day, e.g. "20080730". It's used
    # primarily by the #cache_if calls in views. The optional +request+ object
    # provides a HTTP_HOST so that caching can be done for a particular hostname.
    def self.daily_key_for(name, _request = nil)
      "#{name}@#{Time.zone.now.strftime('%Y%m%d')}"
    end
```

---

</SwmSnippet>

## Expiring all cached data

<SwmSnippet path="/app/observers/calagator/cache_observer.rb" line="18">

---

The <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="20:5:5" line-data="    def self.expire_all">`expire_all`</SwmToken> method clears all cached data. It logs an informational message before clearing the cache.

```

    # Expires all cached data.
    def self.expire_all
      Rails.logger.info 'CacheObserver::expire_all: invoked'
      Rails.cache.clear
    end

    #---[ Triggers ]--------------------------------------------------------
```

---

</SwmSnippet>

## Triggering cache expiration

<SwmSnippet path="/app/observers/calagator/cache_observer.rb" line="26">

---

The <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="27:3:3" line-data="    def after_save(_record)">`after_save`</SwmToken> and <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="32:3:3" line-data="    def after_destroy(_record)">`after_destroy`</SwmToken> methods are callbacks that trigger cache expiration. They invoke the <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="29:5:5" line-data="      self.class.expire_all">`expire_all`</SwmToken> method whenever an <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="8:3:3" line-data="    observe Event, Venue">`Event`</SwmToken> or <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="8:6:6" line-data="    observe Event, Venue">`Venue`</SwmToken> record is saved or destroyed.

```

    def after_save(_record)
      Rails.logger.info 'CacheObserver#after_save: invoked'
      self.class.expire_all
    end

    def after_destroy(_record)
      Rails.logger.info 'CacheObserver#after_destroy: invoked'
      self.class.expire_all
    end
  end
end
```

---

</SwmSnippet>

# Dependencies

The Cache Observer depends on the <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="7:7:9" line-data="  class CacheObserver &lt; ActiveRecord::Observer">`ActiveRecord::Observer`</SwmToken> class and the <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="22:1:3" line-data="      Rails.cache.clear">`Rails.cache`</SwmToken> mechanism. It also uses the <SwmToken path="/app/observers/calagator/cache_observer.rb" pos="21:1:3" line-data="      Rails.logger.info &#39;CacheObserver::expire_all: invoked&#39;">`Rails.logger`</SwmToken> for logging informational messages.

# A joke

Why do programmers prefer dark mode? Because light attracts bugs!

<SwmMeta version="3.0.0" repo-id="Z2l0aHViJTNBJTNBY2FsYWdhdG9yJTNBJTNBY2hyaXNicnVt" repo-name="calagator"><sup>Powered by [Swimm](https://app.swimm.io/)</sup></SwmMeta>
