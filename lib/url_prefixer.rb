class UrlPrefixer
  def self.prefix(value)
    if value.blank? || value.include?("://")
      value
    else
      "http://#{value.lstrip}"
    end
  end
end
