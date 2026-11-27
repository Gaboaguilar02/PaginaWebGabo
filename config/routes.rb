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

  # Perspectiva del cliente: solicitar y seguir servicios de reparación (solo rol cliente)
  namespace :cliente do
    root "repair_cases#index"

    resources :repair_cases, path: "solicitudes", only: %i[ index new create show ] do
      member do
        patch :cancelar
        patch :calificar
      end
    end

    # Endpoints JSON de los dropdowns dependientes del formulario de solicitud
    get "lookups/cities", to: "lookups#cities", as: :lookups_cities
    get "lookups/companies", to: "lookups#companies", as: :lookups_companies
  end

  # Panel de la empresa: solicitudes, ranking mensual de técnicos y bonos escalonados (solo rol empresa)
  namespace :empresa do
    root "dashboard#index"

    resources :repair_cases, path: "solicitudes", only: %i[ index show ] do
      member do
        patch :aceptar
        patch :rechazar
        patch :asignar
      end
    end

    get "ranking", to: "rankings#index", as: :ranking
    patch "requisitos", to: "requisitos#update", as: :requisitos
    resources :technicians, path: "tecnicos", only: %i[ index edit update ]
    resources :bonus_tiers, path: "escalones", except: :show
    resources :bonus_payments, path: "pagos", only: %i[ index create ]
  end

  # Panel del técnico: sus casos asignados, avance del servicio y su desempeño en el ranking (solo rol técnico)
  namespace :tecnico do
    root "dashboard#index"

    resources :repair_cases, path: "casos", only: %i[ index show ] do
      member do
        patch :salir
        patch :iniciar
        patch :resolver
        post :evidencias
      end
    end

    get "desempeno", to: "desempeno#index", as: :desempeno
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
