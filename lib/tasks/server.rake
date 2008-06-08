namespace :server do
  require 'erb'
  require 'yaml'
  require 'uri'

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
      yaml_struct_for("#{RAILS_ROOT}/config/mongrel_cluster.yml")["environment"]
    end
  end

  def manage_solr(action)
    # Doesn't pass hostname, but solr ignores that anyway
    sh "rake RAILS_ENV=#{server_rails_env} PORT=#{solr_port} solr:#{action}"
  end

  desc "Deploy"
  task :deploy do
    sh "ssh calagator@calagator.org 'cd app; svn update; rake restart'"
  end

  desc "Deploy and migrate database"
  task :deploy_and_migrate do
    sh "ssh calagator@calagator.org 'cd app; svn update; rake db:migrate restart'"
  end

  desc "Config"
  task :config => ["tmp:create"] do
    if RAILS_ENV != "production"
      puts "WARNING: CREATING CONFIGURATION FILE WHERE 'RAILS_ENV' IS NOT PRODUCTION!"
      puts "         If this is undesirable, rerun task with 'RAILS_ENV=production' option"
    end

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

    Rake::Task['tmp:cache:clear'].invoke
  end

  desc "Stop"
  task :stop do
    sh "mongrel_rails cluster::stop"
    manage_solr(:stop)
  end

  desc "Start"
  task :start => [:clear] do
    manage_solr(:start)
    sh "mongrel_rails cluster::start --clean"
  end

  desc "Restart"
  task :restart => [:clear] do
    manage_solr(:start)
    sh "mongrel_rails cluster::restart"
  end

  desc "Status"
  task :status do
    sh "mongrel_rails cluster::status"
  end
end

# Create aliases for common tasks
for name in %w(deploy deploy_and_migrate config deploy start stop restart status)
  task name.to_sym => "server:#{name}"
end
