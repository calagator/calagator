class Hash

  # Allows for reverse merging where its the keys in the
  # calling hash that wins over those in the <tt>other_hash</tt>.
  # This is particularly useful for initializing an incoming
  # option hash with default values:
  #
  #   def setup(options = {})
  #     options.reverse_merge! :size => 25, :velocity => 10
  #   end
  #
  # The default :size and :velocity is only set if the +options+
  # passed in doesn't already have those keys set.

  def reverse_merge(other)
    other.merge(self)
  end

  # Inplace form of #reverse_merge.

  def reverse_merge!(other)
    replace(reverse_merge(other))
  end

  # Obvious alias for reverse_merge!

  alias_method :reverse_update, :reverse_merge!

  # Same as Hash#merge but recursively merges sub-hashes.

  def recursive_merge(other)
    hash = self.dup
    other.each do |key, value|
      myval = self[key]
      if value.is_a?(Hash) && myval.is_a?(Hash)
        hash[key] = myval.recursive_merge(value)
      else
        hash[key] = value
      end
    end
    hash
  end

  # Same as Hash#merge! but recursively merges sub-hashes.

  def recursive_merge!(other)
    other.each do |key, value|
      myval = self[key]
      if value.is_a?(Hash) && myval.is_a?(Hash)
        myval.recursive_merge!(value)
      else
        self[key] = value
      end
    end
    self
  end

  def recursively(&block)
    yeild inject({}) do |hash, (key, value)|
      if value.is_a?(Hash)
        hash[key] = value.recursively(&block)
      else
        hash[key] = value
      end
      hash
    end
  end

  def recursively!(&block)
    replace(recursively(&block))
  end

end

