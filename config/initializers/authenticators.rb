class Authenticator
  DEFINITIONS = YAML.load_file(ENV['AUTHENTICATORS_PATH']||'config/authenticators.yml')

  class << self
    def all
      @all ||= DEFINITIONS[Rails.env]
    end

    def method_missing(*args)
      return nil
    end
  end
end