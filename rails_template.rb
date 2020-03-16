# frozen_string_literal: true

require 'rubygems'
require 'pathname'

RAILS_REQUIREMENT = '~> 4.2'

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  puts "Calagator requires Rails #{RAILS_REQUIREMENT}. You are using #{rails_version}."
  exit 1
end

assert_minimum_rails_version

generating_dummy = ARGV.include? '--dummy'
calagator_checkout = Pathname.new(File.expand_path(__dir__))
relative_calagator_path = calagator_checkout.relative_path_from(Pathname.new(destination_root))

if options[:database] == 'postgresql' && ARGV.any? { |arg| arg =~ /--postgres-username=(\w+)/ }
  inside('config') do
    run "sed -e 's/username: .*/username: #{Regexp.last_match(1)}/' -i -- database.yml"
  end
end

# FactoryBot and Faker are required for Calagator's db:seed task
spec = Gem::Specification.load(File.expand_path('calagator.gemspec', __dir__))
spec ||= Gem::Specification.find_by(name: 'calagator')
required_dev_gems = %w[factory_bot_rails faker]

gem_group :development, :test do
  if spec
    spec_dependencies = spec.development_dependencies.select { |dep| required_dev_gems.include?(dep.name) }
    spec_dependencies.each do |dep|
      gem(+dep.name, dep.requirement.to_s)
    end
  else
    required_dev_gems.each { |gem_name| gem gem_name }
  end
end

gem 'calagator', (generating_dummy && { path: relative_calagator_path.to_s })
run 'bundle install'
rake 'db:create'
inside('app/assets') do
  create_file('config/manifest.js') do
    <<-MANIFEST.strip_heredoc
      //= link application.js
      //= link application.css
      //= link calagator/manifest.js
    MANIFEST
  end
end
generate 'calagator:install', (generating_dummy && '--dummy')
generate 'sunspot_rails:install'
