desc "Clear all caches"
task :clear => ['tmp:cache:clear', 'server:clear', 'themes:cache:remove']
