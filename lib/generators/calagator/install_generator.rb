module Calagator
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    class_option :dummy, type: :boolean, default: false

    def install
      add_route
      add_initializers
      add_javascripts
      add_stylesheets
      add_assets
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

    def add_initializers
      initializer '01_calagator.rb', File.read(File.expand_path('../templates/config/initializers/01_calagator.rb', __FILE__))
      initializer '02_geokit.rb',    File.read(File.expand_path('../templates/config/initializers/02_geokit.rb', __FILE__))
      initializer '03_recaptcha.rb', File.read(File.expand_path('../templates/config/initializers/03_recaptcha.rb', __FILE__))
    end

    def add_javascripts
      append_file 'app/assets/javascripts/application.js', '//= require calagator'
    end

    def add_stylesheets
      append_file 'app/assets/stylesheets/application.css', '//= require calagator'
    end

    def add_assets
      run "cp #{File.expand_path("../../../../app/assets/images/spinner.gif", __FILE__)} app/assets/images/"
      run "cp #{File.expand_path("../../../../app/assets/images/site-icon.png", __FILE__)} app/assets/images/"
    end

    def add_seeds
      append_file 'db/seeds.rb', 'Calagator::Engine.load_seed'
    end
  end
end
