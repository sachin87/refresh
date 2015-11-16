Rails.application.routes.draw do

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users, :controllers => { omniauth_callbacks: "users/omniauth_callbacks", passwords: "devise/passwords", registrations: "devise/registrations" }

  resources :orders, only: [:index, :new, :create], path_names: { new: 'checkout' }

  resource :user, only: [:edit, :update] do
    member do
      post :add_credit_card, defaults: {format: 'json'}
      get :remove_credit_card
    end
  end

  get 'cart' => 'cart#index'
  patch 'cart/add'
  delete 'cart/remove'
  patch 'cart/update'

  root 'pages#landing'
  get 'notifications' => 'pages#notifications'
  get 'home' => 'pages#home'
  get 'account' => 'pages#account'

  get 'help' => 'pages#help'
  get 'about' => 'pages#about'
  get 'partners' => 'pages#partners'
  get 'terms' => 'pages#terms'
  get 'privacy' => 'pages#privacy'
  get 'blog' => 'pages#blog'
  get 'contact' => 'pages#contact'
  get 'drivers' => 'pages#drivers'

  resources :stores, only: [:show]

  # These must be the last routes in the file, since they'll match anything
  post '/:city' => 'stores#search_by_address'
  get '/:city' => 'stores#search_by_city'
end
