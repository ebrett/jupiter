Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Email verification routes
  get "/verify_email/:token", to: "email_verification#verify", as: :verify_email
  post "/resend_verification", to: "email_verification#resend", as: :resend_verification

  # Registration route
  post "/users", to: "registrations#create"
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

  # Account linking routes
  namespace :account do
    resource :nationbuilder_link, only: [ :show, :create, :destroy ] do
      member do
        get :status
      end
    end

    resource :nationbuilder_sync, only: [ :create ]
  end

  resources :roles, except: [ :new, :create, :destroy ] do
    member do
      get :users_with_role
    end
  end

  # OAuth routes
  get "/auth/nationbuilder", to: "nationbuilder_auth#redirect"
  get "/auth/nationbuilder/callback", to: "nationbuilder_auth#callback"

  # Component examples (development only)
  if Rails.env.development?
    get "component_examples", to: "component_examples#index"
    get "component_examples/buttons", to: "component_examples#buttons"
    get "component_examples/forms", to: "component_examples#forms"
    get "component_examples/modals", to: "component_examples#modals"
    get "component_examples/tables", to: "component_examples#tables"
    get "component_examples/navigation", to: "component_examples#navigation"
    get "component_examples/alerts", to: "component_examples#alerts"
    get "component_examples/cards", to: "component_examples#cards"
    get "component_examples/dropdowns", to: "component_examples#dropdowns"
    get "component_examples/profiles", to: "component_examples#profiles"
  end
end
