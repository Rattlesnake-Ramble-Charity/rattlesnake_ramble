Rails.application.routes.draw do
  root 'pages#home'
  
  get 'welcome/index'

  get '/home', to: 'pages#home'
  get '/thanks', to: 'pages#thanks'
  get '/charity', to: 'pages#charity'
  get '/race_reports', to: 'pages#race_reports'
  get '/kids_course_description', to: 'pages#kids_course_description'
  get '/odd_year_course_description', to: 'pages#odd_year_course_description'
  get '/even_year_course_description', to: 'pages#even_year_course_description'

  devise_for :users

  resources :races
  resources :racers
  
  resources :race_editions do
    member do
      get 'enter'
      post 'create_entry'
      get 'racer_emails'
      get 'recruitment_emails'
      get 'racer_info_csv'
      get 'race_entries'
      get 'payment_success'
      get 'payment_cancelled'
      get 'checkin_sheet'

    end
  end
  
  resources :race_entries, except: [:index, :show, :new, :create] do
    member do
      get 'successful_entry'  
      get 'cancelled_payment'
    end
  end
  
  resources :products
end
