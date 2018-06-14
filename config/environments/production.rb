Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.serve_static_files = true
  config.assets.js_compressor = :uglifier
  config.assets.compile = true
  config.assets.debug = false
  config.assets.digest = true
  config.assets.prefix = '/assets'
  config.log_level = :info
  config.request_elapsed_time_threshold = 10
  config.i18n.fallbacks = true
  config.active_support_deprecation = :notify
  config.log_formatter = ::Logger::Formatter.new
  config.active_record.dump_schema_after_migration = false
  config.action_controller.relative_url_root = '/cyber-indicators'
  config.active_record.raise_in_transactional_callbacks = true
end
