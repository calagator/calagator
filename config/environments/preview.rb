# Preview environment is the Production environment but using the Development database. Great for local manual testing and debugging Production-only bugs.

eval File.read("#{RAILS_ROOT}/config/environments/production.rb")
