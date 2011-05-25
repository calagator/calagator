# Preview environment is the Production environment but using the Development database. Great for local manual testing and debugging Production-only bugs.

eval File.read(Rails.root.join('config','environments','production.rb'))
