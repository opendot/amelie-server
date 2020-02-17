require 'api_constraints'

Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth', controllers: { registrations: 'overrides/registrations', sessions:  'overrides/sessions' }
  get 'reset_password', controller: :utility_pages

  root 'application#root'

  namespace :api, defaults: { format: :json }, path: '/' do

    # Default version of the routes must be the last one, otherwise it will capture every route bypassing the version request
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      # users' routes.
      resources :users, only:[:show, :update] do
        collection do
          post :on_network
          put :disable
        end
      end
      resources :parents, defaults: { type: 'Parent' }, only: [:index, :show, :update]
      resources :researchers, defaults: { type: 'Researcher' }, only: [:index, :show, :update]
      resources :superadmins, defaults: { type: 'Superadmin' }, only: [:index, :show, :update]
      resources :teachers, defaults: { type: 'Teacher' }, only: [:index, :show, :update]

      resources :patients, only: [:index, :show] do
        resources :tracker_calibration_parameters, only: [:show, :update]
        resources :available_boxes, only: [:index], :controller => "patients/available_boxes"
        resources :boxes, only: [:index], :controller => "patients/boxes"
        resources :levels, only: [:index], :controller => "patients/levels"
        resources :queued_synchronizables, only: [:index], :controller => "patients/queued_synchronizables"
      end

      # sessions' routes
      resources :communication_sessions, defaults: { type: "CommunicationSession" }, only: [:create]
      resources :cognitive_sessions, defaults: { type: 'CognitiveSession' }, only: [:create] do
        get "results", :to => "cognitive_sessions#results"
      end
      resources :learning_sessions, defaults: { type: 'LearningSession' }, only: [:create]
      resources :calibration_sessions, defaults: { type: 'CalibrationSession' }, only: [:create]
      resources :training_sessions, only: [:create] do
        resources :tracker_raw_data, only: [:create]
        collection do
          post :align_eyetracker
          post :change_route
        end
      end

      # tracker calibration parameters' routes
      resources :tracker_calibration_parameters, defaults: { type: "TobiiCalibrationParameter" }, only: [:create]

      # cards and card tags' routes
      resources :card_tags, only: [:index, :show] do
        resources :cards, only: [:index]
      end
      resources :archived_cards, defaults: { type: 'ArchivedCard' }, only: [:index, :show]
      resources :preset_cards, defaults: { type: 'PresetCard' }, only: [:index, :show]
      resources :custom_cards, defaults: { type: 'CustomCard' }, only: [:create, :update, :index, :show, :destroy]
      post "custom_cards_form_data", to: 'cards#create_form_data', defaults: {type: 'CustomCard'}
      put "custom_cards_form_data/:id", to: 'cards#update_form_data', defaults: {type: 'CustomCard'}
      resources :cards, only: [:index, :show]

      resources :audio_files, only: [:create, :update]

      # pages and page tags' routes
      resources :page_tags, only: [:index, :show] do
        resources :pages, only: [:index]
      end
      resources :custom_pages, defaults: { type: 'CustomPage' }, only: [:create, :update, :index, :show]
      resources :preset_pages, defaults: { type: 'PresetPage' }, only: [:index, :show]
      resources :feedback_pages, defaults: { type: 'FeedbackPage' }, only: [:show]
      resources :archived_card_pages, defaults: { type: 'ArchivedCardPage' }, only: [:index, :show]
      resources :archived_idle_pages, defaults: { type: 'ArchivedIdlePage' }, only: [:index, :show]
      resources :pages, only: [:index, :show]

      # session events routes -- operator
      resources :load_tree_events, defaults: { type: 'LoadTreeEvent' }, only: [:create]
      resources :jump_to_page_events, defaults: { type: 'JumpToPageEvent' }, only: [:create]
      resources :back_events, defaults: { type: 'BackEvent' }, only: [:create]
      resources :sound_alert_events, defaults: { type: 'SoundAlertEvent' }, only: [:create]
      resources :visual_alert_events, defaults: { type:'VisualAlertEvent' }, only: [:create]
      resources :eyetracker_lock_events, defaults: { type: 'EyetrackerLockEvent' }, only: [:create]
      resources :eyetracker_unlock_events, defaults: { type: 'EyetrackerUnlockEvent' }, only: [:create]
      resources :shuffle_events, defaults: { type: 'ShuffleEvent' }, only: [:create]
      resources :tracker_calibration_parameter_change_events, defaults: { type: 'TrackerCalibrationParameterChangeEvent' }, only: [:create]
      resources :play_video_events, defaults: { type: 'PlayVideoEvent' }, only: [:create]
      resources :pause_video_events, defaults: { type: 'PauseVideoEvent' }, only: [:create]
      resources :end_video_events, defaults: { type: 'EndVideoEvent' }, only: [:create]
      resources :end_extra_page_events, defaults: { type: 'EndExtraPageEvent' }, only: [:create]

      # session events routes -- patient
      resources :patient_eye_choice_events, defaults: { type: 'PatientEyeChoiceEvent' }, only: [:create]
      resources :patient_touch_choice_events, defaults: { type: 'PatientTouchChoiceEvent' }, only: [:create]
      resources :patient_user_choice_events, defaults: { type: 'PatientUserChoiceEvent' }, only: [:create]

      # session events routes -- system
      resources :timeout_events, defaults: { type: 'TimeoutEvent' }, only: [:create]
      resources :transition_to_page_events, defaults: { type: 'TransitionToPageEvent' }, only: [:create]
      resources :transition_to_end_events, defaults: { type: 'TransitionToEndEvent' }, only: [:create]
      resources :transition_to_idle_events, defaults: { type: 'TransitionToIdleEvent' }, only: [:create]

      # trees
      resources :custom_trees, defaults: { type: 'CustomTree'}
      resources :preview_trees, only: [:destroy]

      # Images
      resources :personal_files, :constraints => { :id => /[0-9A-Za-z\-\.\_%]+/ }, only: [:show, :index]

      # Games
      resources :games, only: [:create, :destroy]

      # Synchronization
      resources :synchronizations, only: [:create, :index]
      post 'new_data', to: 'synchronizations#post_new_data', as: 'post_new_data'
      get 'new_data', to: 'synchronizations#get_new_data', as: 'get_new_data'

      # Sign-in
      devise_scope :user do
        post "sign_in", to: 'sign_in#create', as: 'local_login'
      end
    end
  end

  # If no route matches avoid routing errors
  get ":url" => "application#not_found", :constraints => { :url => /.*/ }

  mount ActionCable.server => '/cable'
end
