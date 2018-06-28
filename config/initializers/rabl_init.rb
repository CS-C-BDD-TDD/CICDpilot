require 'rabl'

module Rabl
  class Engine
    alias_method :old_apply, :apply

    def apply(context_scope, locals, &block)
      locals[:associations] ||= {}
      old_apply(context_scope, locals, &block)
    end
  end

  class Configuration
    attr_accessor :force_iso_dates
  end
  class Builder
    def to_hash(object = nil, settings = {}, options = {})
      @_object = object           if object
      @options.merge!(options)    if options
      @settings.merge!(settings)  if settings

      cache_results do
        @_result = {}

        # Merges directly into @_result
        compile_settings(:attributes)

        merge_engines_into_result

        # Merges directly into @_result
        compile_settings(:node)

        replace_nil_values          if Rabl.configuration.replace_nil_values_with_empty_strings
        replace_empty_string_values if Rabl.configuration.replace_empty_string_values_with_nil_values
        remove_nil_values           if Rabl.configuration.exclude_nil_values
        force_iso_dates             if Rabl.configuration.force_iso_dates

        result = @_result
        result = { @options[:root_name] => result } if @options[:root_name].present?
        result
      end
    end

    protected
    def force_iso_dates
      @_result = @_result.inject({}) do |new_hash, (k, v)|
        new_hash[k] = v.respond_to?(:iso8601) ? v.iso8601 : v
        new_hash
      end
    end
  end
end

Rabl.configure do |config|
  # Commented as these are defaults
  # config.cache_all_output = false
  # config.cache_sources = Rails.env != 'development' # Defaults to false
  # config.cache_engine = Rabl::CacheEngine.new # Defaults to Rails cache
  # config.perform_caching = false
  # config.escape_all_output = false
  # config.json_engine = nil # Class with #dump class method (defaults JSON)
  # config.msgpack_engine = nil # Defaults to ::MessagePack
  # config.bson_engine = nil # Defaults to ::BSON
  # config.plist_engine = nil # Defaults to ::Plist::Emit
   config.include_json_root = false
  # config.include_msgpack_root = true
  # config.include_bson_root = true
  # config.include_plist_root = true
  # config.include_xml_root  = false
   config.include_child_root = false
  # config.enable_json_callbacks = false
  # config.xml_options = { :dasherize  => true, :skip_types => false }
  # config.view_paths = []
  # config.raise_on_missing_attribute = true # Defaults to false
  # config.replace_nil_values_with_empty_strings = true # Defaults to false
   config.replace_empty_string_values_with_nil_values = true # Defaults to false
  # config.exclude_nil_values = true # Defaults to false
  # config.exclude_empty_values_in_collections = true # Defaults to false
   config.force_iso_dates = true
end

