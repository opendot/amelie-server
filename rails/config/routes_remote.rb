require 'api_constraints'

Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers: { registrations: 'overrides/registrations', sessions:  'overrides/sessions' }
  get 'reset_password', controller: :utility_pages

  root 'application#root'

  namespace :api, defaults: { format: :json }, path: '/' do

    # Default version of the routes must be the last one, otherwise it will capture every route bypassing the version request
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      # users' routes.

      resources :patients, only: [:index, :create, :show, :update, :destroy] do
        resources :levels, only: [:index, :create, :show, :update, :destroy] do
          resources :available_exercise_trees, param: :exercise_tree_id, only: [:index], controller: "patients/levels/available_exercise_trees"
        end
        resources :tracker_calibration_parameters, only: [:show]
        resources :available_exercise_trees, param: :exercise_tree_id, only: [:show, :update], controller: "patients/available_exercise_trees"
        resources :available_levels, only: [:index], controller: "patients/available_levels"
        resources :badges, only: [:index], controller: "patients/badges"
        resources :cognitive_sessions, defaults: { type: 'CognitiveSession' }, only: [:index, :show], controller: "patients/training_sessions"
        resources :communication_sessions, defaults: { type: "CommunicationSession" }, only: [:index, :show], controller: "patients/training_sessions"
        resources :daily_activities, param: :date, only: [:index, :show], controller: "patients/daily_activities"
        resources :stats, only: [:index], controller: "patients/stats"
        resources :training_sessions, only: [:index, :show], controller: "patients/training_sessions" do
          resources :session_events, only: [:index], controller: "patients/training_sessions/session_events"
          resources :tracker_raw_data, only: [:index], controller: "patients/training_sessions/tracker_raw_data"
        end
        resources :widgets, only: [:index], controller: "patients/widgets"
      end

      resources :users, only: [:index, :show, :update, :destroy] do
        resources :patients, only: [:update, :destroy], controller: "users/patients"
        collection do
          put :disable
        end
      end

      resources :cards, only: [] do
        collection do
          put "selection_sounds", to: "cards#selection_sounds"
        end
      end

      # API for backoffice resources creation
      resources :levels, only: [:index, :create, :show, :update, :destroy] do
        collection do
          put "order", to: "levels#order"
        end
        resources :boxes, only: [:index, :create, :show, :update, :destroy], controller: "levels/boxes"
      end
      resources :boxes do
        resources :targets, only: [:index, :create, :show, :update, :destroy], controller: "boxes/targets" do
          collection do
            put "order", to: "boxes/targets#order"
          end
        end
      end
      resources :targets do
        resources :exercise_trees, defaults: { type: 'ExerciseTree'}, only: [:index, :create, :show, :update, :destroy], controller: "targets/exercise_trees" do
          collection do
            put "order", to: "targets/exercise_trees#order"
          end
        end
      end

      resources :cognitive_cards, defaults: { type: 'CognitiveCard'}, only: [:index, :create, :show, :update, :destroy] do
        resources :exercise_trees, defaults: { type: 'ExerciseTree'}, only: [:index], controller: "cognitive_cards/exercise_trees"
      end
      resources :feedback_pages, defaults: { type: 'FeedbackPage'}, only: [:index, :create, :show, :update, :destroy]

      resources :audio_files, only: [:create]

      # Synchronization
      resources :synchronizations, only: [:create, :index]
      post 'new_data', to: 'synchronizations#post_new_data', as: 'post_new_data'
      get 'new_data', to: 'synchronizations#get_new_data', as: 'get_new_data'

      #resources :contents, only: [:update]
      put 'audio_files', to: 'audio_files#update', as:'audio_file_batch_update'
      put 'contents', to: 'contents#update', as:'content_batch_update'

      # Data export
      resources :packages, only: [:index]

      # Geoentities
      resources :geoentities, only: [:index]

      # Georeferenced stats
      resources :georeferenced_stats, only: [:index]

      # Notices
      resources :notices, only: [:index, :update]

      # Invites
      resources :invites, only: [:index, :create]

      # Preference
      resources :preferences, only: [:index] do
        collection do
          put :change
        end
      end


    end
  end

  # If no route matches avoid routing errors
  get ":url" => "application#not_found", :constraints => { :url => /.*/ }

  mount ActionCable.server => '/cable'
end
