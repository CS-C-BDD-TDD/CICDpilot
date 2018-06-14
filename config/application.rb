require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CyberIndicators
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.assets.paths << Rails.root.join('vendor','assets','auth','fonts')
    config.assets.paths << Rails.root.join('vendor','assets','auth','ace')
    config.assets.precompile += %w(.svg .eot .woff .ttf)
    config.paths['config/environments'] = ENV['RAILS_CONFIG_ENVIRONMENTS'] || '/etc/cyber-indicators/config/environments'
    config.paths['config/database'] = ENV['RAILS_DB_YAML'] || '/etc/cyber-indicators/config/database.yml'
    config.paths['config/secrets'] = ENV['RAILS_SECRETS_YAML'] || '/etc/cyber-indicators/config/secrets.yml'

    config.autoload_paths += %W(#{config.root}/serializers)

    # Set the version variable
    config.version = nil # needs to be set, even if to nil
    begin
      yml = YAML.load_file('/etc/cyber-indicators/config/version.yml')
      if yml["version"].present?
        config.version = yml["version"]
      else
        puts "WARNING: Your version.yml file is present, but doesn't contain a variable called version"
      end
    rescue Errno::ENOENT
      puts "INFO: /etc/cyber-indicators/config/version.yml not found" unless Rails.env == 'development' || Rails.env == 'test'
    rescue Psych::SyntaxError
      puts "WARNING: Your version.yml file is present, but is not formatted as YAML"
    end
    if ENV['VERSION'].present?
      config.version = ENV['VERSION']
    end

    config.action_dispatch.perform_deep_munge = false
    config.middleware.insert_after "Rails::Rack::Logger", "PingNoDb"

    config.after_initialize do
      begin
        if ActiveRecord::Base.connection.table_exists?(:user_sessions)
          UserSession.delete_all
        end
      rescue
      end
    end
  end
end
