namespace :db do
  namespace :raw do
    desc 'Dump database to FILE or name of RAILS_ENV'
    task :dump do
      verbose(true) unless Rake.application.options.silent

      struct = database_settings
      target = ENV['FILE'] || "#{Rails.env}.sql"
      target_tmp = "#{target}.tmp"
      adapter = struct.adapter

      case adapter
      when 'sqlite3'
        source = struct.database
        sh "sqlite3 #{Shellwords.escape source} .dump > #{Shellwords.escape target}"
      when 'mysql'
        sh "mysqldump --add-locks --create-options --disable-keys --extended-insert --quick --set-charset #{mysql_credentials_for struct} > #{Shellwords.escape target_tmp}"
        mv target_tmp, target
      when 'postgresql'
        sh "pg_dump #{postgresql_credentials_for struct} --clean --no-owner --no-privileges --file #{Shellwords.escape target_tmp}"
        mv target_tmp, target
      else
        raise ArgumentError, "Unknown database adapter: #{adapter}"
      end
    end

    desc 'Restore database from FILE'
    task :restore do
      verbose(true) unless Rake.application.options.silent

      source = ENV['FILE']
      raise ArgumentError, 'No FILE argument specified to restore from' unless source

      struct = database_settings
      adapter = struct.adapter

      case adapter
      when 'sqlite3'
        target = struct.database
        mv target, "#{target}.old" if File.exist?(target)
        # Ignore the "no such table: sqlite_sequence" errors
        sh "sqlite3 #{Shellwords.escape target} < #{Shellwords.escape source} || true"
      when 'mysql'
        sh "mysql #{mysql_credentials_for struct} < #{Shellwords.escape source}"
      when 'postgresql'
        sh "psql #{postgresql_credentials_for struct} < #{Shellwords.escape source}"
      else
        raise ArgumentError, "Unknown database adapter: #{adapter}"
      end

      Rake::Task['clear'].invoke
      Rake::Task['db:migrate'].invoke
    end
  end

  # Return OpenStruct representing current environment's database.yml file.
  def database_settings
    require 'erb'
    require 'yaml'
    require 'ostruct'

    return @database_settings_cache ||= OpenStruct.new(
      YAML.load(
        ERB.new(
          File.read(
            File.join(Rails.root, 'config', 'database.yml'))).result)[Rails.env])
  end

  # Return string with MySQL credentials for use on a command-line.
  def mysql_credentials_for(struct)
    result = []
    result << "--user=#{Shellwords.escape struct.username}" if struct.username
    result << "--password=#{Shellwords.escape struct.password}" if struct.password
    result << "--host=#{Shellwords.escape struct.host}" if struct.host
    result << "#{Shellwords.escape struct.database}"
    return result.join(' ')
  end

  # Return string with PostgreSQL credentials for use on a command-line.
  def postgresql_credentials_for(struct)
    result = []
    result << "-U #{Shellwords.escape struct.username}" if struct.username
    result << "-h #{Shellwords.escape struct.host}" if struct.host
    result << "-p #{Shellwords.escape struct.port}" if struct.port
    result << "#{Shellwords.escape struct.database}"
    return result.join(' ')
  end
end
