Rails.application.routes.draw do
  # Devise routes for authentication
  devise_for :users, skip: [ :sessions ] do
    # Custom API authentication routes
    post "users/sign_in", to: "devise/sessions#create"
    delete "users/sign_out", to: "devise/sessions#destroy"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "health#show", as: :rails_health_check

  # Test endpoint for authentication
  get "test_auth" => "health#test_auth"

  # Defines the root path route ("/")
  # root "posts#index"
end
