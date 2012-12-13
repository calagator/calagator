namespace :spec do
  namespace :rcov do
    # Don't add tasks these tasks unless RSpec has been installed and loaded by Bundler
    if defined?(RSpec::Core::RakeTask)
      SPEC_OPTS_COMMON = []
      RCOV_OPTS_COMMON = ['--rails', '--exclude', 'osx/objc,gems/,spec/,features/']
      COVERAGE_INFO = "#{Rails.root}/coverage.info"
      COVERAGE_DIFF_LOG = "#{Rails.root}/log/rcov.log"

      # Private task to assert that RCov is installed, else fails with helpful error messages.
      task :assert_rcov => :environment do
        if (defined?(RUBY_ENGINE) && ! %w[mri ruby].include?(RUBY_ENGINE)) || RUBY_VERSION != "1.8.7"
          raise "ERROR: rcov is not available for your platform, it only supports MRI Ruby 1.8.7"
        elsif ! defined?(Rcov)
          raise "ERROR: rcov is not activated, run `touch .dev && bundle` to activate -- see `./Gemfile` for details"
        end
      end

      desc 'Run all specs and save the code coverage data'
      RSpec::Core::RakeTask.new(:save => :assert_rcov) do |t|
        t.rcov = true
        t.rcov_opts = RCOV_OPTS_COMMON + ['--save', COVERAGE_INFO]
        t.spec_opts = SPEC_OPTS_COMMON
      end

      RSpec::Core::RakeTask.new(:diff => :assert_rcov) do |t|
        t.rcov = true
        t.rcov_opts = RCOV_OPTS_COMMON + ['--text-coverage-diff', COVERAGE_INFO, '--no-color']
        t.spec_opts = SPEC_OPTS_COMMON
        t.rspec_opts << "2>&1 | tee #{COVERAGE_DIFF_LOG}; echo '# Saved rcov diff report to: #{COVERAGE_DIFF_LOG}'"
      end

      desc 'Clean up, delete coverage report and coverage status'
      task :clean do
        rm_r 'coverage' rescue nil
        rm_r 'coverage.info' rescue nil
      end
    end
  end
end
