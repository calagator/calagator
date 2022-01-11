# frozen_string_literal: true

source 'https://rubygems.org'

# Declare your gem's dependencies in calagator.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# develop against latest rails
gem 'rails', '~> 5.2'

# turbolinks is used by the test application by default
gem 'turbolinks'

gem 'recaptcha', require: 'recaptcha/rails'

# can't declare platform specific development dependencies in the gemspec.
gem 'byebug', platform: 'mri'
gem 'paper_trail_manager', git: 'https://github.com/fusion94/paper_trail_manager.git', ref: 'b8630cd0e3318ad0929b80a701a18175402a4944'

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.
gem 'launchy'

gem 'rails-controller-testing', group: 'test'
