desc "Generate rtags"
task :rtags do
  sh "rtags --vi --recurse app lib"
end
