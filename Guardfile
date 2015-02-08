# Run specs
guard 'rspec', cmd: "bundle exec rspec" do
  watch(%r{^app/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/.+_spec\.rb|^leech_media.rb$})
end
