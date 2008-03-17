my_formats = {
  :yyyymmdd => '%Y-%m-%d',
  :long_date => '%A, %B %d, %Y',
}

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(my_formats)
ActiveSupport::CoreExtensions::Date::Conversions::DATE_FORMATS.merge!(my_formats)
