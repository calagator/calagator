namespace :db do
  namespace :import do
    
    desc "RESTfully pull data from the production server and populate the local database."
    task (:production => :environment) do

      # Don't pollute the root namespace with conflicting classes
      module RemoteCalagator
        def self.resources
          self.constants.reject {|v| v=="CalagatorResource" }
        end
    
        class CalagatorResource < ActiveResource::Base
          self.site = SETTINGS.url
      
          # Infers the name of the local version of a class by looking for it in the root namespace.
          def self.local_class
            Kernel.const_get(self.name.sub(self.parent.name+'::',''))
          end
      
          # Retuns a local version of the remote object
          def to_local
            returning self.class.local_class.find_or_create_by_id(self.id) do |local|
              self.attributes.each do |key,value|
                local.send(key+'=',value)
              end
            end
          end
      
        end

        class Event < CalagatorResource
        end

        class Venue < CalagatorResource
        end

        # FIXME: We can't pull sources yet because the controller isn't giving out XML.
        # Implement xml in the controller, then uncomment before deploying.
    
        # class Source < CalagatorResource
        # end

      end
  
      RemoteCalagator.resources.each do |resource|
        print "Fetching #{resource.pluralize}"
        [RemoteCalagator.const_get(resource).find(:all)].flatten.each do |remote|
          remote.to_local.save!
          print '.'
        end
        puts '[done]'
      end
  
    end

  end
end
