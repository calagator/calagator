module Calagator
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def install
      run 'bundle install'
      add_route
      add_secrets
      rake 'calagator:install:migrations'
      rake 'db:migrate'
    end

    private

    def add_route
      inject_into_file 'config/routes.rb', "mount Calagator::Engine => '/'\n", after: "Application.routes.draw do\n"
    end

    def add_secrets
      copy_file File.expand_path(File.join(__FILE__, '../templates/secrets.yml.sample')), 'config/secrets.yml'
    end

  end
end
