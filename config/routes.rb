Rails.application.routes.draw do
  root :to => 'main#index'

  namespace :auth do
    get "login" => "sessions#new"
    delete "logout" => "sessions#destroy"
    resources :sessions,only:[:create]
  end

  namespace :tou do
    get "acceptance" => "acceptance#new"
    post "acceptance" => "acceptance#create"
  end

  get "/search", to: 'searches#index'

  resources :indicators_sightings, :id => /([^\/])+?/, :format => false
  resources :indicators_kill_chain_phases, :id => /([^\/])+?/, :format => false
  resources :indicators_packages, :id => /([^\/])+?/, :format => false
  resources :indicators_threat_actors, :id => /([^\/])+?/, :format => false
  resources :kill_chains, :id => /([^\/])+?/, :format => false
  resources :dns_records, :id => /([^\/])+?/, format: false
  resources :dns_queries, :id => /([^\/])+?/, format: false
  resources :email_messages, :id => /([^\/])+?/, format: false
  resources :files, :id => /([^\/])+?/, format: false
  resources :file_hashes, :id => /([^\/])+?/, :format => false
  resources :hostnames, :id => /([^\/])+?/, format: false
  resources :http_sessions, :id => /([^\/])+?/
  resources :links, :id => /([^\/])+?/, format: false
  resources :mutexes, :id => /([^\/])+?/, format: false
  resources :network_connections, :id => /([^\/])+?/, format: false
  resources :ports, :id => /([^\/])+?/, format: false
  resources :questions, :id => /([^\/])+?/, format: false
  resources :registries, :id => /([^\/])+?/, format: false
  resources :resource_records, :id => /([^\/])+?/, format: false
  resources :socket_addresses, :id => /([^\/])+?/, format: false
  resources :uris, :id => /([^\/])+?/, format: false
  post '/notes', to: 'notes#create'
  delete '/notes/:id', to: 'notes#destroy'
  resources :reported_issues
  resources :email_files, :id => /([^\/])+?/, format: false, only:[:update]
  resources :email_links, :id => /([^\/])+?/, format: false, only:[:update]
  resources :badge_statuses, :id => /([^\/])+?/, format: false

  resources :ais_statistics, :id => /([^\/])+?/, format: false
  get 'ais_statistics_metrics', to: 'ais_statistics#build_metrics'

  # domains
  get "/domains/valid", to: 'domains#valid', as: 'valid_domain'
  resources :domains, :id => /([^\/])+?/, format: false

  # pmap/ipset
  get "/pmap/:tag_name", to: 'threat_actors#pmap', as: 'tag_pmap'
  get "/ipset/:tag_name", to: 'threat_actors#ipset', as: 'tag_ipset'

  resources :addresses, :id => /([^\/])+?/, format: false
  resources :stix_packages, :id => /([^\/])+?/, format: false do
    get "download_stix_package" => "stix_packages#download", format: :xml
    get "download_ais_package" => "stix_packages#download_ais", format: :xml
  end
  put "stix_package/bulk_ind/:id", to: 'stix_packages#bulk_inds'
  put "stix_package/coa_additions/:id", to: 'stix_packages#coa_additions'
  post "stix_package/suggested_packages/:limit", to: 'stix_packages#suggested_packages'

  resources :sources, :id => /([^\/])+?/, :format => false
  get "sources/get_by_id/:id", to:'sources#get_by_package_id'
  #delete "sources/delete/:guid", to:'sources#destroy'

  resources :threat_actors, :id => /([^\/])+?/, format: false
  put "threat_actors/bulk_ind/:id", to: 'threat_actors#bulk_inds'
  
  resources :course_of_actions, :id => /([^\/])+?/, format: false

  resources :exploit_targets, :id => /([^\/])+?/, format: false
  resources :exploit_target_packages, :id => /([^\/])+?/, :format => false
  resources :exploit_target_vulnerabilities, :id => /([^\/])+?/, :format => false
  resources :exploit_target_course_of_actions, :id => /([^\/])+?/, :format => false

  resources :ttps, :id => /([^\/])+?/, format: false

  resources :attack_patterns, :id => /([^\/])+?/, format: false

  resources :vulnerabilities, :id => /([^\/])+?/, format: false

  resources :stix_markings, :id => /([^\/])+?/, format: false
  
  resources :contributing_sources, :id => /([^\/])+?/, format: false
  
  resources :downloads, to: "transfers#download", as: 'download', :defaults => { :format => 'xml' }

  resources :indicators, :id => /([^\/])+?/, format: false do
    resources :system_tags
    resources :user_tags
    #collection do
    #  post :bulk_create
    #end
  end

  get "public_indicators",to: 'indicators#public_indicators'
  get "weather_map_indicators", to: 'indicators#weather_map_indicators'
  put "indicators/bulk_tags/:id", to: 'indicators#bulk_tags'
  put "indicators/coa_additions/:id", to: 'indicators#coa_additions'
  post "indicators/related_by_cbx_indicators/:limit", to: 'indicators#related_by_cbx_indicators'

  resources :observables, :id => /([^\/])+?/, :format => false
  resources :sightings, :id => /([^\/])+?/, :format => false
  resources :permissions, :id => /([^\/])+?/, :format => false
  resources :tags
  resources :system_tags do
    resources :indicators, :id => /([^\/])+?/, :format => false
  end

  resources :user_tags do
    resources :indicators, :id => /([^\/])+?/, :format => false
  end
  resources "uploadzip", to: "transfers#upload", as: 'upload'
  post "uploads/attachment", to: "uploads#attachment", as: 'attachment'
  get "uploads/attachment/:id", to: "uploads#download_attachment", as: "download_attachment"
  delete 'uploads/attachment/:id', to: 'uploads#destroy_attachment', as: "destroy_attachment"
  resources :uploads, :only => [:create, :index, :new, :show]
  resources :heatmaps, :id => /([^\/])+?/, :format => false,
                       controller: :weather_map_heatmaps,
                       only: [:create, :index, :show]
  resources :groups do
    get 'permissions', controller: :permissions, action: :index
  end
  resources :exported_indicators

  put "exported_indicators/bulk_inds/:id", to: 'exported_indicators#bulk_inds'

  resources :relationships, only:[:create,:update,:destroy]

  get '/settings/current', to: 'settings#current', as: 'current_settings'

  get '/show_xml/:id', to: 'uploads#display_original_xml'

  # current user route needs to come first
  get '/users/current', to: 'users#current', as: 'current_user'
  get '/users/new_password/:id', to: 'users#new_password', as: 'new_password'
  post '/users/generate_api_key', to: 'users#generate_api_key', as: 'generate_api_key'
  post '/users/revoke_api_key', to: 'users#revoke_api_key', as: 'revoke_api_key'
  post '/users/change_api_key_secret', to: 'users#change_api_key_secret', as: 'change_api_key_secret'
  post '/users/enable_disable', to: 'users#enable_disable', as: 'enable_disable_user'
  put '/users/change_password/:id', to: 'users#change_password', as: 'change_password'
  resources :users
  put '/users/bulk/:id', to: 'users#bulk_add_to_group', as: 'bulk_add_to_group'
  resources :organizations

  post '/stix/upload', to: 'stix_packages#upload'

  # Weather Map upload
  post 'ipreputation', to: 'addresses#create_weather_map'
  get 'weather_map_addresses', to: 'addresses#index' , defaults: {weather_map_only: true}

  # Weather Map domains upload
  post 'domainreputation', to: 'domains#create_weather_map'
  get 'weather_map_domains', to: 'domains#index' , defaults: {weather_map_only: true}

  # Weather Map Stats for Weather Map Dashboard
  get 'weather_map_address_stats', to: 'weather_map_stats#build_addresses'
  get 'weather_map_domain_stats', to: 'weather_map_stats#build_domains'

  get 'ping', to: 'main#ping', as: :ping

  put 'validate_classification/:obj_type', to: 'classifications#validate_classification'

  resources :acs_sets
  resources :human_reviews
  resources :human_review_disseminate, to: 'human_reviews#disseminate'
  resources :ciap_id_mappings, only: [:index, :create]
  resources :system_logs, controller: 'logging/system_logs'
  resources :layer_seven_connections, only: [:index, :create]
  namespace :logging do
  get "dashboard" => "dashboard#report"
  get "disseminated" => "disseminated_logs#index"
  end

  # FO Stats page
  get '/fo_stats', to: 'threat_actors#fo_stats'
  resources :ping_session, to: 'user_session#ping'


end
