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


if yes?("Is this for development on the Calagator gem? [yes/no]")
  gpath = ask("Please enter the local path to the gem (defaults to remote gem if path does not exist):")
  if Dir.exists?(gpath)
    gem "calagator", (generating_dummy && { path: relative_calagator_path.to_s }), path: gpath
  else
    puts "Not a valid path, installing remote gem"
    gem "calagator", (generating_dummy && { path: relative_calagator_path.to_s })
  end
else
  gem "calagator", (generating_dummy && { path: relative_calagator_path.to_s })
end

# gem "calagator", (generating_dummy && { path: relative_calagator_path.to_s })
run "bundle install"
rake "db:create"
generate "calagator:install", (generating_dummy && "--dummy")
generate "sunspot_rails:install"

