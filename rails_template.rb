# frozen_string_literal: true

require "rubygems"
require "pathname"
require_relative "./lib/calagator/version"

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(Calagator::RAILS_VERSION)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  puts "Calagator requires Rails #{Calagator::RAILS_VERSION}. You are using #{rails_version}."
  exit 1
end

assert_minimum_rails_version

generating_test_app = ARGV.include? "--test_app"
calagator_checkout = Pathname.new(File.expand_path(__dir__))
relative_calagator_path = calagator_checkout.relative_path_from(Pathname.new(destination_root))

if options[:database] == "postgresql" && ARGV.any? { |arg| arg =~ /--postgres-username=(\w+)/ }
  inside("config") do
    run "sed -e 's/username: .*/username: #{Regexp.last_match(1)}/' -i -- database.yml"
  end
end

# FactoryBot and Faker are required for Calagator's db:seed task
spec = Gem::Specification.load(File.expand_path("calagator.gemspec", __dir__))
spec ||= Gem::Specification.find_by_name("calagator")
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

gem "calagator", Calagator::VERSION, (generating_test_app ? {path: relative_calagator_path.to_s} : {})
run "bundle install"
rails_command "db:create"
inside("app/assets") do
  append_to_file("config/manifest.js") do
    <<-MANIFEST.strip_heredoc
      //= link application.js
      //= link application.css
    MANIFEST
  end
end
generate "calagator:install", "--test-app #{generating_test_app}"
