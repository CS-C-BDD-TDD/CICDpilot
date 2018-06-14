module Serialized extend ActiveSupport::Concern
  included do |base|
    define_method(:serializer) do
      begin
        (base.to_s + 'Serializer').constantize
      rescue NameError, NoMethodError
        ''
      end
    end
  end

  def as_json(options = {})
    unless options.include?(:only) || options.include?(:include) || options.include?(:methods) || options.include?(:except) || options[:single]
      @single = options[:single]
      @single = is_single? if @single.nil?
      serializer = options[:serializer]if options[:serializer]
      serializer ||= self.serializer

      if serializer.present?

        serializer = serializer.new(@single,self)
        custom_methods = (serializer.methods - Serializer.instance_methods).select {|meth| meth.to_s.first != '_' && meth.to_s.last != '?'}

        self.instance_eval do
          custom_methods.each do |meth|
            define_singleton_method(meth,serializer.method(meth).to_proc)
          end
        end

        # Association options support the disabling of associations from the
        # render by passing the association set to "none" in the locals as
        # was supported prior to the move from rabl to serializers.
        association_opts =
            options[:locals].present? && options[:locals].is_a?(Hash) &&
                options[:locals][:associations].is_a?(Hash) ?
                options[:locals][:associations] : {}

        attributes,methods = translate_attributes(serializer.attributes)
        associations = translate_association_hash(serializer.associations,
                                                  association_opts)

        methods += custom_methods
        options[:only] = attributes
        options[:methods] = methods
        options[:include] = associations
      end
    end

    root = if options && options.key?(:root)
             options[:root]
           else
             include_root_in_json
           end

    if root
      root = model_name.element if root == true
      hsh = { root => serializable_hash(options) }
    else
      hsh = serializable_hash(options)
    end

    if serializer.present?
      custom_nodes = serializer.nodes.collect {|n| {n.keys.first => n.values.first.call(self)}.as_json}
      custom_nodes.each { |n| hsh.merge!(n) if n.present? && n.is_a?(Hash)}
      hsh
    end
  end

  private

  def is_single?
    caller.each {|a| return false if a.include?("object/json.rb:140:in `map'")}
    true
  end

  def translate_attributes(attrs,klass = self.class)
    attributes = []
    methods = []
    names = klass.column_names
    attrs.each do |attribute|
      if names.include?(attribute.to_s)
        attributes << attribute
      elsif klass.instance_methods.include?(attribute)
        methods << attribute
      end
    end
    return attributes, methods
  end

  def get_serializer(sym)
    begin
      (sym.to_s.classify + 'Serializer').constantize
    rescue NameError
      nil
    end
  end

  def klass_from_association(sym,options='')
    begin
      (sym.to_s.classify).constantize
    rescue NameError
      nil
    end
  end

  def translate_association_hash(associations, opts={})
    return [] unless associations.present?
    associations = [associations] unless associations.is_a?(Array)
    new_assocations = []
    associations.each do |association|
      if association.is_a? Hash
        association.each_pair do |key,value|
          # If the locals passed to the renderer have this association
          # flagged as "none," it should be skipped.
          next if opts[key] == 'none'
          #next if association[key].is_a?(Hash) && (association[key].keys.include?(:only) || association[key].keys.include?(:include) || association[keys].include?(:as))
          if value[:serializer].present?
            serializer = value[:serializer]
          else
            serializer = get_serializer(key)
          end

          if value[:class_name].present?
            klass = value[:class_name]
          else
            klass = klass_from_association(key)
          end

          # If opts[key] is a hash, we need to pass this nested hash to handle
          # nested associations in recursive calls to this method.
          nested_opts = opts[key].is_a?(Hash) ? opts[key] : {}

          if serializer.present? && klass.present?
            attributes, methods = translate_attributes(serializer.attributes,klass)
            attributes = association[key][:only] || attributes
            new_assocations.push({key => {as: association[key][:as], only: attributes,methods: methods,include: translate_association_hash(association[key][:include], nested_opts)}})
          else
            new_assocations.push({key => {as: association[key][:as],only: association[key][:only],except: association[key][:except],include: translate_association_hash(association[key][:include], nested_opts)}})
          end
        end
      elsif association.is_a? Symbol
        # If the locals passed to the renderer have this association
        # flagged as "none," it should be skipped.
        next if opts[association] == 'none'
        serializer = get_serializer(association)
        klass = klass_from_association(association)

        if serializer.present? && klass.present?
          attributes, methods = translate_attributes(serializer.attributes,klass)
          new_assocations.push({association => {only: attributes, methods: methods}})
        else
          new_assocations.push(association)
        end
      end
    end
    new_assocations
  end
end
