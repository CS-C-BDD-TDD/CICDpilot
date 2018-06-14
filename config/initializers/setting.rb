class Setting
  DEFINITIONS = YAML.load_file(ENV['RAILS_SETTINGS_YAML'] || 'config/settings.yml')

  class << self
    env = Rails.env
    if env=='dbadmin'
      env='production'
    end

    (DEFINITIONS[env]||[]).each do |setting_name,value|
      define_method(setting_name) do
        value
      end
    end

    def all
      env = Rails.env
      if env=='dbadmin'
        env='production'
      end

      settings=Array.new
      (DEFINITIONS[env]||[]).each do |setting_name,value|
        settings.push(:name=>setting_name,:value=>value)
      end
      settings
    end

    def method_missing(*args)
      return Default.send(*args) || nil
    end

  end
end
