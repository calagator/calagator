ActionController::Routing::Routes.draw do |map|

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  map.connect 'omfg',  :controller => 'site', :action => 'omfg'
  map.connect 'hello', :controller => 'site', :action => 'hello'
  map.connect 'about', :controller => 'site', :action => 'about'

  # Normal controllers
  map.resources :events, :collection => {'duplicates' => :get, 'squash_multiple_duplicates' => :post, 'search' => :get}
  map.resources :sources, :collection => { :import => :put }
  map.resources :venues, :collection => {'duplicates' => :get, 'squash_multiple_duplicates' => :post}

  # Export action
  map.connect 'export', :controller => 'site', :action => 'export'
  map.connect 'export.:format', :controller => 'site', :action => 'export'
  
  # Stylesheets
  map.connect 'css/:name', :controller => 'site', :action => 'style'
  map.connect 'css/:name.:format', :controller => 'site', :action => 'style'

  # Site root
  map.root :controller => "site"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
