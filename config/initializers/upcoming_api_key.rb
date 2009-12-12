default_upcoming_api_key = 'f12d0c34c0'

if SECRETS.upcoming_api_key.blank? or SECRETS.upcoming_api_key == default_upcoming_api_key
  SECRETS.upcoming_api_key = default_upcoming_api_key
  puts "WARNING!: Using default Upcoming API key, see 'API Keys' in INSTALL.md"
end
