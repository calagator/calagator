# frozen_string_literal: true

namespace :spec do
  namespace :db do
    databases = %i[postgresql mysql sqlite3]

    desc 'Run specs against all databases'
    task :all do
      failed = false

      databases.each do |database|
        test_against database
      end
    end

    databases.each do |database|
      desc "Run specs against '#{database}' database"
      task database do
        return test_against database
      end
    end

    def test_against(kind)
      sample = Rails.root + "config/database~#{kind}.sample.yml"
      custom = Rails.root + 'config/database~custom.yml'
      backup = Rails.root + 'config/database~custom.yml.backup'

      mv custom, backup if custom.exist?

      cp sample, custom

      succeeded = nil

      begin
        Dir.chdir(Rails.root) do
          puts
          puts "## Database: #{kind}"
          succeeded = system 'unset BUNDLE_GEMFILE BUNDLE_BIN_PATH RUBYOPT; bundle --quiet && rake db:create:all db:migrate db:test:prepare spec'
        end
      ensure
        rm custom

        mv backup, custom if backup.exist?
      end

      raise "Tests failed against database '#{kind}'" unless succeeded
    end
  end
end
