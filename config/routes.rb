Rails.application.routes.draw do

  root 'stripe_payments#index'
  resources :stripe_payments, only: [:index]
  get 'setup',                      to: 'stripe_payments#setup'
  post 'create_checkout_session',   to: 'stripe_payments#create_checkout_session'
  get 'checkout_session',           to: 'stripe_payments#checkout_session'
  post 'customer_portal',           to: 'stripe_payments#customer_portal'
  get 'success',                    to: 'stripe_payments#success'
  get 'canceled',                   to: 'stripe_payments#canceled'
  
end
