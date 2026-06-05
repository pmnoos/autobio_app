Rails.application.routes.draw do
  resources :users, only: [ :new, :create ]
  resources :photos do
    collection do
      patch :reorder
    end
    member do
      get :pdf
    end
  end
  resources :chapters do
    collection do
      get :list
      get :export_pdf
    end
    member do
      get :export_chapter_pdf
    end
    # Nested route for photos accessed from chapters
    resources :photos, only: [ :show ], controller: "photos" do
      member do
        get :show, path: "", to: "photos#show_from_chapter"
      end
    end
  end
  resource :session
  get "session" => redirect("/session/new")
  resources :passwords, param: :token
  get "info" => "info#index", as: :info
  get "info/chapter32" => "info#chapter32", as: :info_chapter32
  get "info/chapter13" => "info#chapter13", as: :info_chapter13
  get "info/chapter26" => "info#chapter26", as: :info_chapter26
  get "info/chapter3" => "info#chapter3", as: :info_chapter3
  get "info/chapter18" => "info#chapter18", as: :info_chapter18
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "chapters#index"

  # Audio playback routes
  get "audio" => "audio#index", as: :audio_index
  # Use a wildcard so filenames can include extensions (e.g., .mp3)
  get "audio/stream/*filename" => "audio#stream", as: :audio_stream
  # Gracefully handle missing filename by redirecting to the audio index
  get "audio/stream" => redirect("/audio")
  # Trigger audio generation (background)
  post "audio/generate" => "audio#generate", as: :audio_generate

  # Static pages
  get "chapters/export/docx_test", to: "chapters#export_docx_test"

  get "about" => "pages#about"
  get "privacy" => "pages#privacy"
  get "terms" => "pages#terms"
  get "contact" => "pages#contact"
  get "/book", to: "book#show"
  # Alias plural path to singular book route
  get "/books", to: redirect("/book")
end
