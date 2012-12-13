desc "Clear"
task :clear => ['tmp:cache:clear', 'themes:remove_cache'] do
  for file in ['public/stylesheets/all.css', 'public/javascripts/all.js']
    path = Rails.root + file
    if File.exist?(path)
      puts "Removing #{path}"
      rm path
    end
  end
end
