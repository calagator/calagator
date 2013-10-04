desc "Clear"
task :clear => ['tmp:cache:clear', 'assets:clean']
