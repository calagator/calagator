namespace :server do
  desc "Deploy"
  task :deploy do
    sh "ssh calagator@calagator.org 'cd app; svn update; rake RAILS_ENV=production restart'"
  end

  desc "Config"
  task :config => ["tmp:create"] do
    target = "config/mongrel_cluster.yml"
    source = "#{target}.erb"
    require "erb"
    template = File.read(source)
    File.open(target, "w+") do |h|
      h.write(ERB.new(template, 0, "%<>-").result)
    end
    puts File.read(target)
  end

  desc "Clear"
  task :clear do
    for file in ['public/stylesheets/all.css', 'public/javascripts/all.js']
      rm file if File.exist?(file)
    end

    pid_dir = 'tmp/pids'
    if File.exist? pid_dir
      for pid_file in FileList["#{pid_dir}/*.pid"]
        pid = File.read(pid_file)
        begin
          Process.kill(0, pid.to_i)
        rescue Errno::ESRCH => e
          rm pid_file, :verbose => true
        end
      end
    end
      
    Rake::Task['tmp:cache:clear'].invoke
  end

  desc "Stop"
  task :stop => :clear do
    sh "mongrel_rails cluster::stop"
  end

  desc "Start"
  task :start => :clear do
    sh "mongrel_rails cluster::start"
  end

  desc "Restart"
  task :restart => :clear do
    sh "mongrel_rails cluster::restart"
  end

  desc "Status"
  task :status do
    sh "mongrel_rails cluster::status"
  end
end

# Create aliases for common tasks
for name in %w(deploy config deploy start stop restart status)
  task name.to_sym => "server:#{name}"
end
