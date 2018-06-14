class ActionController::Base
  def render(*args, &block)
    case args[0]
      when String
        if args[0].include?('.json')
          lookup_context.rendered_format = :json
          if args[1].present?
            args[1].merge!({content_type: 'application/json'}) unless args[1].keys.include?(:content_type)
          else
            args << {content_type: 'application/json'} unless args.include?({content_type: 'application/json'})
          end
        end
      when Hash
        if args[0].keys.include?(:json)
          lookup_context.rendered_format = :json
          args[0].merge!({content_type: 'application/json'}) unless args[0].keys.include?(:content_type)
        end
    end
    options = _normalize_render(*args, &block)
    self.response_body = render_to_body(options)
    _process_format(rendered_format, options) if rendered_format
    self.response_body
  end
end