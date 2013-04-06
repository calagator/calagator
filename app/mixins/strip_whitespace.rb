module StripWhitespace
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def strip_whitespace!(*fields)
      before_validation do |record|
        fields.each do |field|
          setter = "#{field}=".to_sym
          value = record.send(field.to_sym)
          if value.respond_to?(:strip) and record.respond_to?(setter)
            record.send(setter, value.strip)
          end
        end
      end
    end
  end
end