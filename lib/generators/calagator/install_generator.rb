module Calagator
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def install
      run 'bundle install'
      add_route
      add_secrets
      add_initializer
      rake 'calagator:install:migrations'
      rake 'db:migrate'
      rake 'db:test:prepare'
      run 'rm -f public/index.html'
    end

    private

    def add_route
      inject_into_file 'config/routes.rb', "\s\smount Calagator::Engine => '/'\n", after: "Application.routes.draw do\n"
    end

    def add_secrets
      copy_file File.expand_path(File.join(__FILE__, '../templates/config/secrets.yml.sample')), 'config/secrets.yml'
    end

    def add_initializer
      copy_file File.expand_path(File.join(__FILE__, '../templates/config/calagator.rb')), 'config/initializers/calagator.rb'
    end

  end
end
