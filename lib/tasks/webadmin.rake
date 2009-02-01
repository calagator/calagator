namespace :webadmin do
  desc "Run webadmin in foreground"
  task :run do
    verbose do
      sh "(cd webadmin && thin --rackup config.ru start)"
    end
  end

  desc "Start webadmin process"
  task :start do
    verbose do
      sh "(cd webadmin && thin --rackup config.ru --daemonize start)"
    end
  end

  desc "Stop webadmin process"
  task :stop do
    verbose do
      sh "(cd webadmin && thin --rackup config.ru stop)"
    end
  end

  desc "Restart webadmin process"
  task :restart do
    verbose do
      sh "(cd webadmin && thin --rackup config.ru restart)"
    end
  end
end
