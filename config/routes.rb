Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # System namespace for health and oauth
  namespace :system do
    resources :health, only: [ :index ]
    resources :oauth_status, only: [ :index ] do
      collection do
        get :export
      end
    end
  end

  # Admin dashboard (can be renamed or left as is)
  get "admin", to: "admin#index"

  # Flattened user and role management
  resources :users, except: [ :new, :create ] do
    member do
      get :manage_roles
      post :assign_role
      delete :remove_role
    end
    collection do
      post :bulk_assign_roles
    end
  end

  resources :roles, except: [ :new, :create, :destroy ] do
    member do
      get :users_with_role
    end
  end

  # OAuth routes
  get "/auth/nationbuilder", to: "nationbuilder_auth#redirect"
  get "/auth/nationbuilder/callback", to: "nationbuilder_auth#callback"
end
