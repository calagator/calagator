class SourceParser
  class AbstractEvent < Struct.new(
    :title,
    :description,
    :start_time,
    :end_time,
    :url,
    :location,
    :tags)

    def initialize(*args)
      super
      self.tags ||= []
    end
  end
end
