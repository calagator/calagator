namespace :spec do
  namespace :db do
    databases = [:postgresql, :mysql, :sqlite3]

    desc "Run specs against all databases"
    task :all do
      failed = false

      databases.each do |database|
        failed = true unless test_against database
      end

      if failed
        fail "## Error: At least one of the specs above failed"
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
      custom = Rails.root + "config/database~custom.yml"
      backup = Rails.root + "config/database~custom.yml.backup"

      if custom.exist?
        mv custom, backup
      end

      cp sample, custom

      result = nil

      begin
        Rails.root.chdir do
          puts
          puts "## Database: #{kind}"
          result = system "bundle --quiet && rake db:create:all db:migrate db:test:prepare spec"
        end
      ensure
        rm custom

        if backup.exist?
          mv backup, custom
        end
      end

      return result
    end
  end
end
