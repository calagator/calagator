require 'rubygems'
require 'pathname'

RAILS_REQUIREMENT = "~> 4.0"

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  puts "Calagator requires Rails #{RAILS_REQUIREMENT}. You are using #{rails_version}."
  exit 1
end

assert_minimum_rails_version

generating_dummy = ARGV.include? "--dummy"
calagator_checkout = Pathname.new(File.expand_path("..", __FILE__))
relative_calagator_path = calagator_checkout.relative_path_from(Pathname.new(destination_root))

if options[:database] == "postgresql" && ARGV.any? { |arg| arg =~ /--postgres-username=(\w+)/ }
  inside('config') do
    run "sed -e 's/username: .*/username: #{$1}/' -i -- database.yml"
  end
end

# FactoryGirl and Faker are required for Calagator's db:seed task
spec = Gem::Specification::load(File.expand_path("../calagator.gemspec", __FILE__))
spec ||= Gem::Specification::find_by_name('calagator')
required_dev_gems = ["factory_girl_rails", "faker"]


gem_group :development, :test do
  if spec
    spec_dependencies = spec.development_dependencies.select{|dep| required_dev_gems.include?(dep.name) }
    spec_dependencies.each do |dep|
      gem dep.name, dep.requirement.to_s
    end
  else
    required_dev_gems.each{|gem_name| gem gem_name }
  end
end

gem "calagator", (generating_dummy && { path: relative_calagator_path.to_s })
run "bundle install"
rake "db:create"
generate "calagator:install", (generating_dummy && "--dummy")
generate "sunspot_rails:install"

