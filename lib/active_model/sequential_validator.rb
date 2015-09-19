class SequentialValidator < ActiveModel::Validator
  def validate record
    values = options[:attributes].map do |attribute|
      record.send(attribute)
    end.compact
    if values.sort != values
      record.errors.add options[:attributes].last, "cannot be before #{options[:attributes].first}"
    end
  end
end

