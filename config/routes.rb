Calagator::Application.routes.draw do
  match 'omfg' => 'site#omfg'
  match 'hello' => 'site#hello'
  match 'about' => 'site#about'
  match 'opensearch.:format' => 'site#opensearch'

  resources :events do
    collection do
  post :squash_multiple_duplicates
  get :search
  get :duplicates
  end
    member do
  get :clone
  end

  end

  resources :sources do
    collection do
  put :import
  end
  

  end

  resources :venues do
    collection do
  post :squash_multiple_duplicates
  get :map
  get :duplicates
  end


  end

  resources :versions
  match 'export' => 'site#export'
  match 'export.:format' => 'site#export'
  match 'css/:name' => 'site#style'
  match 'css/:name.:format' => 'site#style'
  match '/' => 'site#index'
  match '/themes/:theme/images/*filename' => 'theme#images', :as => :theme_images
  match '/themes/:theme/stylesheets/*filename' => 'theme#stylesheets', :as => :theme_stylesheets
  match '/themes/:theme/javascript/*filename' => 'theme#javascript', :as => :theme_javascript
  match '/:controller(/:action(/:id))'
end
