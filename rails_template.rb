require 'pathname'

generating_dummy = ARGV.include? "--dummy"
calagator_checkout = Pathname.new(File.expand_path("..", __FILE__))
relative_calagator_path = calagator_checkout.relative_path_from(Pathname.new(destination_root))

if options[:database] == "postgresql" && ARGV.any? { |arg| arg =~ /--postgres-username=(\w+)/ }
  inside('config') do
    run "sed -e 's/username: .*/username: #{$1}/' -i -- database.yml"
  end
end

gem "calagator", (generating_dummy && { path: relative_calagator_path.to_s })
run "bundle install"
rake "db:create"
generate "calagator:install", (generating_dummy && "--dummy")
