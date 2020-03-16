unless ENV['SKIP_COVERAGE'] || RUBY_ENGINE == 'rbx'
  require 'simplecov-lcov'

  SimpleCov::Formatter::LcovFormatter.config do |c|
    c.report_with_single_file = true
    c.output_directory = 'coverage'
    c.lcov_file_name = 'lcov.info'
    c.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.start 'rails' do
    enable_coverage :branch
    coverage_dir 'coverage'

    add_filter %r{lib/generators}
    add_filter %r{lib/tasks}
    add_filter 'lib/calagator/version.rb'

    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter
    ])
  end
end
