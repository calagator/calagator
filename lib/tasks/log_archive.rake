desc "Move and compress logs to log/archive/"
task "log:archive" do
  # Rails logging fails if you simply rename the logs because it'll keep trying
  # to append to those previously-opened filehandles. The following approach
  # keeps those files intact and simply truncates them.
  require 'date'
  log_dir = File.join(RAILS_ROOT, "log")
  archive_dir = File.join(log_dir, "archive")
  timestamp = DateTime.now.strftime

  mkdir_p(archive_dir) unless File.directory?(archive_dir)
  Dir["#{log_dir}/*.log"].each do |source|
    next unless File.new(source).stat.size > 0
    target = File.join(archive_dir, "#{File.basename(source)}.#{timestamp}")
    target_archive = "#{target}.gz"

    #puts "#{source} & #{target_archive}"
    # FIXME some requests will be lost due to a race condition between these two commands
    sh("gzip -c #{source} > #{target_archive}")
    sh("cat /dev/null > #{source}")
  end
end
