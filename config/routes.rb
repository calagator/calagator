Calagator::Engine.routes.draw do
  get 'omfg' => 'site#omfg'
  get 'hello' => 'site#hello'

  get 'about' => 'site#about'

  get 'opensearch.:format' => 'site#opensearch'
  get 'defunct' => 'site#defunct'

  get 'admin' => 'admin#index'
  get "admin/index"
  get "admin/events"
  post "lock_event" => "admin#lock_event"

  resources :events do
    collection do
      post :squash_many_duplicates
      get :search
      get :duplicates
      get 'tag/:tag', action: :search, as: :tag
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
      get 'tag/:tag', action: :index, as: :tag
    end
  end

  resources :versions, :only => [:edit]

  # Rails 4.0 prevents referencing controllers outside of the Calagator namespace.
  # Work around this by aliasing PaperTrailManager inside Calagator:
  Calagator::PaperTrailManager ||= ::PaperTrailManager
  resources :changes, controller: 'paper_trail_manager/changes'

  # In Rails 4.1+, we could use a leading slash to the controller path:
  # resources :changes, controller: '/paper_trail_manager/changes'

  get 'recent_changes' => redirect("/changes")
  get 'recent_changes.:format' => redirect("/changes.%{format}")

  get 'css/:name' => 'site#style'
  get 'css/:name.:format' => 'site#style'

  get '/' => 'site#index', :as => :root
  get '/index' => 'site#index'
  get '/index.:format' => 'site#index'
end
