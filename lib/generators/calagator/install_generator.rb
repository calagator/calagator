module Calagator
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    class_option :dummy, type: :boolean, default: false

    def install
      add_route
      add_secrets
      add_initializer
      add_javascripts
      add_stylesheets
      add_seeds
      run 'rm -f public/index.html'
      unless options[:dummy]
        rake 'calagator:install:migrations'
        rake 'db:migrate'
        rake 'db:test:prepare'
      end
    end

    private

    def add_route
      inject_into_file 'config/routes.rb', "\s\smount Calagator::Engine => '/'\n", after: "routes.draw do\n"
    end

    def add_secrets
      copy_file File.expand_path(File.join(__FILE__, '../templates/config/secrets.yml.sample')), 'config/secrets.yml'
    end

    def add_initializer
      initializer 'calagator.rb', File.read(File.expand_path('../templates/config/calagator.rb', __FILE__))
    end

    def add_javascripts
      append_file 'app/assets/javascripts/application.js', '//= require calagator'
    end

    def add_stylesheets
      append_file 'app/assets/stylesheets/application.css', '//= require calagator'
    end

    def add_seeds
      append_file 'db/seeds.rb', 'Calagator::Engine.load_seed'
    end
  end
end
