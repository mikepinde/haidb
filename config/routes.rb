Rails.application.routes.draw do
  devise_for :staffs # office people
  devise_for :users, controllers: {
      registrations: 'users/devise/registrations',
      confirmations: 'users/devise/confirmations'
  }

  root :to => "public_signups#new"
  get '/de/*ignore' => redirect('/?locale=de')
  get '/en/*ignore' => redirect('/?locale=en')

  # participant signup
  resources :public_signups, only: [:new, :create] do
    collection do
      get 'thank_you'
    end
  end

  namespace :office do

    resources :angels do
      collection do
        get 'map'
      end
      resources :memberships, only: [:new]
      resources :angel_registrations, path: 'registrations', as: 'registrations', only: [:new, :create, :destroy]
    end

    get '/similar_angels/name', to: 'similar_angels#match_by_name'
    post '/similar_angels/name', to: 'similar_angels#merge'
    get '/similar_angels/email', to: 'similar_angels#match_by_email'
    post '/similar_angels/email', to: 'similar_angels#merge'

    resources :events do
      resources :direct_debts, only: [:new, :create]
      collection do
        get 'past'
      end
      member do
        post 'completed'
      end
      resource :event_report, only: [], as: 'report', path: 'report' do
        collection do
          get 'site'
          get 'bank'
          get 'client_history'
          get 'email'
          get 'status'
          get 'checklist'
          get 'roster'
          get 'payment'
          get 'map'
          get 'completed'
          get 'checked_in'
        end
      end
    end

    resources :memberships do
      collection do
        post 'refresh'
      end
    end

    resources :teams do
      resources :members do
        collection do
          post 'refresh'
        end
      end
      collection do
        get 'past'
      end
      member do
        post 'assign', to: 'team_assignments#create'
      end
    end

    resources :public_signups do
      collection do
        get 'approved'
        get 'waitlisted'
      end
      member do
        put 'approve'
        put 'waitlist'
      end
    end

    resources :messages, only: [:index, :new, :create, :show]
    resources :email_names
    resources :site_defaults
    resources :registrations do
      member do
        post 'completed'
        post 'checked_in'
      end
      resources :payments
    end
    resources :dashboards, only: [:index]
    root to: 'dashboards#index'
  end

  namespace :users do
    get 'signup_requested', to: 'not_signed_in#signup_requested'
    get 'confirmed', to: 'not_signed_in#confirmed'
    resources :dashboards, only: [:index]
    resources :registrations, only: [:index]
    resources :teams, only: [:index, :show] do
      resource :member, only: [:create, :destroy, :edit, :update]
    end
    resource :angel, only: [:new, :create, :edit, :update, :show]
    resources :rosters, only: [:show]
    root to: 'dashboards#index'
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
