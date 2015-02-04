Calagator::Application.routes.draw do
  match 'omfg' => 'site#omfg'
  match 'hello' => 'site#hello'

  match 'about' => 'site#about'

  match 'opensearch.:format' => 'site#opensearch'
  match 'defunct' => 'site#defunct'

  resources :events do
    collection do
      post :squash_many_duplicates
      get :search
      get :duplicates
      match 'tag/:tag', via: :get, to: :search, as: :tag
    end

    member do
      get :clone
    end
  end

  resources :sources do
    collection do
      post :import
    end
  end

  resources :venues do
    collection do
      post :squash_many_duplicates
      get :map
      get :duplicates
      get :autocomplete
      match 'tag/:tag', via: :get, to: :search, as: :tag
    end
  end

  resources :versions, :only => [:edit]
  resources :changes, :controller => 'paper_trail_manager/changes'
  match 'recent_changes' => redirect("/changes")
  match 'recent_changes.:format' => redirect("/changes.%{format}")

  match 'css/:name' => 'site#style'
  match 'css/:name.:format' => 'site#style'

  match '/' => 'site#index', :as => :root
  match '/index' => 'site#index'
  match '/index.:format' => 'site#index'

end
