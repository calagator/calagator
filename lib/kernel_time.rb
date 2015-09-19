def Time(value)
  value = value.join(' ') if value.kind_of?(Array)
  value = value.to_s if value.kind_of?(Date)
  value = Time.zone.parse(value) if value.kind_of?(String) # this will throw ArgumentError if invalid
  value
end
