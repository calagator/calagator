# frozen_string_literal: true

source 'https://rubygems.org'

# Declare your gem's dependencies in calagator.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# develop against latest rails
gem 'rails', '~> 5.2'

# turbolinks is used by the test application by default
gem 'turbolinks', '~> 5.2.1'

gem 'recaptcha', '~> 5.9.0', require: 'recaptcha/rails'

# can't declare platform specific development dependencies in the gemspec.
gem 'byebug', '~> 11.1.3', platform: 'mri'

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
gem 'launchy', '~> 2.5.2'

gem 'rails-controller-testing', '~> 1.0.5', group: 'test'
