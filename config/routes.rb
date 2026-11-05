Rails.application.routes.draw do
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Módulo de administración (solo rol admin)
  namespace :admin do
    root "dashboard#index"

    resources :companies do
      member { patch :cambiar_estado }
    end
    resources :users, except: :show
    resources :appliance_types, except: :show
    resources :provinces, except: :show
    resources :cities, except: :show

    # Endpoint JSON del dropdown dependiente: ciudades de una provincia
    get "lookups/cities", to: "lookups#cities", as: :lookups_cities
  end

  resources :products
  root "products#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
