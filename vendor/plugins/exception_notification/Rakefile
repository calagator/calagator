require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test exception_notification gem.'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

desc 'Generate documentation for exception_notification gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'exception_notification'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "super_exception_notifier"
    gemspec.summary = "Allows unhandled (and handled!) exceptions to be captured and sent via email"
    gemspec.description = "Allows customization of:
* Specify which level of notification you would like with an array of optional styles of notification (email, webhooks)
* the sender address of the email
* the recipient addresses
* the text used to prefix the subject line
* the HTTP status codes to notify for
* the error classes to send emails for
* alternatively, the error classes to not notify for
* whether to send error emails or just render without sending anything
* the HTTP status and status code that gets rendered with specific errors
* the view path to the error page templates
* custom errors, with custom error templates
* define error layouts at application or controller level, or use the controller's own default layout, or no layout at all
* get error notification for errors that occur in the console, using notifiable method
* Override the gem's handling and rendering with explicit rescue statements inline.
* Hooks into `git blame` output so you can get an idea of who (may) have introduced the bug
* Hooks into other website services (e.g. you can send exceptions to to Switchub.com)
* Can notify of errors occurring in any class/method using notifiable { method }
* Can notify of errors in Rake tasks using NotifiedTask.new instead of task"
    gemspec.email = "peter.boling@gmail.com"
    gemspec.homepage = "http://github.com/pboling/exception_notification"
    gemspec.authors = ['Peter Boling', 'Scott Windsor', 'Ismael Celis', 'Jacques Crocker', 'Jamis Buck']
    gemspec.add_dependency 'actionmailer'
    gemspec.files = ["MIT-LICENSE",
             "README.rdoc",
             "exception_notification.gemspec",
             "init.rb",
             "lib/super_exception_notifier/custom_exception_classes.rb",
             "lib/super_exception_notifier/custom_exception_methods.rb",
             "lib/super_exception_notifier/deprecated_methods.rb",
             "lib/super_exception_notifier/git_blame.rb",
             "lib/super_exception_notifier/helpful_hashes.rb",
             "lib/super_exception_notifier/hooks_notifier.rb",
             "lib/super_exception_notifier/notifiable_helper.rb",
             "lib/exception_notifiable.rb",
             "lib/exception_notifier.rb",
             "lib/exception_notifier_helper.rb",
             "lib/notifiable.rb",
             "rails/init.rb",
             "rails/app/views/exception_notifiable/400.html",
             "rails/app/views/exception_notifiable/403.html",
             "rails/app/views/exception_notifiable/404.html",
             "rails/app/views/exception_notifiable/405.html",
             "rails/app/views/exception_notifiable/410.html",
             "rails/app/views/exception_notifiable/418.html",
             "rails/app/views/exception_notifiable/422.html",
             "rails/app/views/exception_notifiable/423.html",
             "rails/app/views/exception_notifiable/500.html",
             "rails/app/views/exception_notifiable/501.html",
             "rails/app/views/exception_notifiable/503.html",
             "rails/app/views/exception_notifiable/method_disabled.html.erb",
             "tasks/notified_task.rake",
             "views/exception_notifier/_backtrace.html.erb",
             "views/exception_notifier/_environment.html.erb",
             "views/exception_notifier/_inspect_model.html.erb",
             "views/exception_notifier/_request.html.erb",
             "views/exception_notifier/_session.html.erb",
             "views/exception_notifier/_title.html.erb",
             "views/exception_notifier/background_exception_notification.text.plain.erb",
             "views/exception_notifier/exception_notification.text.plain.erb",
             "views/exception_notifier/rake_exception_notification.text.plain.erb",
             "VERSION.yml"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
