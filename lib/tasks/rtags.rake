task :rtags do
  sh "rtags --vi --recurse app lib vendor/plugins vendor/gems"
end
