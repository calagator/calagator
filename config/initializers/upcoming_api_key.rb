default_upcoming_api_key = 'f12d0c34c0'

if ENV['upcoming_api_key'].blank? or ENV['upcoming_api_key'] == default_upcoming_api_key
  ENV['upcoming_api_key'] = default_upcoming_api_key
  puts "WARNING!: Using default Upcoming API key, see 'API Keys' in INSTALL.md"
end
