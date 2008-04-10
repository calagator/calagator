class SourceParser
  AbstractEvent = Struct.new(
    :title,
    :description,
    :start_time,
    :end_time,
    :url,
    :location)
end
