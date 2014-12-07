class SettingsBag
  def initialize(data)
    @data = data.each_with_object({}) { |(key, value), obj|
      obj[key.to_sym] = value
    }
  end

  # method_missing
  def method_missing(meth, *args, &block)
    @data[meth]
  end

  # respond_to?
  def respond_to?(meth)
    @data.key?(meth)
  end
end

__END__

s = SettingsBag.new({foo: 1})
s.foo # => 1
s.bar(2) -> s.method_missing(:bar, 2)
s.respond_to?(:foo) # => true
