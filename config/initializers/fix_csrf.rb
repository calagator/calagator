# TODO Remove this workaround once it's patched by newer versions of Rails
# http://feeds.feedburner.com/~r/RidingRails/~3/457453697/potential-circumvention-of-csrf-protection-in-rails-2-1

Mime::Type.unverifiable_types.delete(:text)
