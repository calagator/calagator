namespace :server do
  require 'erb'
  require 'yaml'
  require 'uri'

  THIN_YML = "config/thin.yml"

  def yaml_struct_for(filename)
    YAML.load(ERB.new(File.read(filename)).result)
  end

  def solr_port
    return @solr_port ||= begin
      url = yaml_struct_for("#{RAILS_ROOT}/config/solr.yml")[server_rails_env]["url"]
      URI.parse(url).port
    end
  end

  def server_rails_env
    return @server_rails_env ||= begin
      yaml_struct_for(THIN_YML)["environment"]
    end
  end

  def manage_solr(action)
    # Doesn't pass hostname, but solr ignores that anyway
    sh "rake RAILS_ENV=#{server_rails_env} PORT=#{solr_port} solr:#{action}"
  end

  def thin_configured?
    return File.exist?(THIN_YML)
  end

  def manage_thin(action)
    if thin_configured?
      sh "thin --config #{THIN_YML} #{action}"
    else
      Rake::Task['server:help'].invoke
      raise "ERROR: Couldn't find thin config."
    end
  end

  desc "Help configure thin"
  task :help do
      puts <<-HERE
You must create a thin config with a command similar to:

  thin config --config #{THIN_YML} --timeout 3 --daemonize --environment ENV --port PORT --servers SERVERS

E.g.,

  # Production
  thin config --config #{THIN_YML} --timeout 3 --daemonize --port 20010 --servers 2 --environment production

  # Preview
  thin config --config #{THIN_YML} --timeout 3 --daemonize --port 20010 --servers 2 --environment preview
      HERE
  end

  desc "Clear"
  task :clear do
    for file in ['public/stylesheets/all.css', 'public/javascripts/all.js']
      rm file if File.exist?(file)
    end

    Rake::Task['tmp:cache:clear'].invoke
  end

  desc "Stop"
  task :stop do
    manage_thin(:stop)
    manage_solr(:stop)
  end

  desc "Start"
  task :start => [:clear] do
    manage_solr(:start)
    manage_thin(:start)
  end

  desc "Restart"
  task :restart => [:clear] do
    manage_solr(:start)
    manage_thin(:restart)
  end

  # FIXME how to check status of thin?
  desc "Status"
  task :status do
    sh "mongrel_rails cluster::status"
  end
end

# Create aliases for common tasks
for name in %w[start stop restart status]
  task name.to_sym => "server:#{name}"
end
