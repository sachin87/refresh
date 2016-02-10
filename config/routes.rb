Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => {
    omniauth_callbacks: "users/omniauth_callbacks",
    passwords: "devise/passwords",
    registrations: "devise/registrations",
    sessions: "users/sessions"
  }

  resources :orders, only: [:index, :new, :create], path_names: { new: 'checkout' }

  resource :user, only: [:edit, :update] do
    member do
      post :add_credit_card, defaults: {format: 'json'}
      get :remove_credit_card
      get :new_token
    end
  end

  post '/auth/:provider', to: 'auth#authenticate'

  get 'cart' => 'cart#index'
  patch 'cart/add'
  delete 'cart/remove'
  patch 'cart/update'
  patch 'cart/remove_one'

  root 'pages#landing'
  get 'notifications' => 'pages#notifications'
  get 'account' => 'pages#account'

  get 'help' => 'pages#help'
  get 'terms' => 'pages#terms'
  get 'privacy' => 'pages#privacy'

  match '/contact',     to: 'contacts#new', via: 'get'
  resources "contacts", only: [:new, :create]

  match '/drive',     to: 'drivers#new', via: 'get'
  resources "drivers", only: [:new, :create]

  match '/restaurants',     to: 'restaurants#new', via: 'get'
  resources "restaurants", only: [:new, :create]



  # These must be the last routes in the file, since they'll match anything
  post '/:city' => 'stores#search_by_address'
  get '/:city' => 'stores#search_by_city'
  get '/atlanta/:id' => 'stores#show', as: :store
end
