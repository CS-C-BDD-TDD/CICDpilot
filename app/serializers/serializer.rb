class Serializer
  # Builds object attributes into JSON
  #
  # @params [Array] Array of attributes to be written to JSON
  # @params [Block] Block Function provides runtime conditional support, expects boolean return to determine whether to include attributes or not
  # @return none
  def self.attributes(*args, &block)
    @attributes ||= []
    return @attributes if args.blank?
    args.each do |arg|
      define_method('_' + arg.to_s + '?', &block)
    end if block_given?
    @attributes += args
  end

  def self.associate(association=nil,options={}, &block)
    @associations ||= []
    return @associations if association.blank?
    build_boolean([association],&block)
    @associations.push({association => options})
  end

  def self.node(key=nil,conditions={},&block)
    @nodes ||= []
    if key.present?
      @nodes << {key => [conditions,block]}
    else
      @nodes << block
    end
  end

  def self.nodes
    @nodes ||= []
    @nodes
  end

  def initialize(single = true,_caller = nil)
    @single = single
    @caller = _caller
    @attributes = self.class.attributes.collect do |attr|
      @attr = attr
      if self.class.method_defined?('_' + attr.to_s + '?')
        attr if self.send('_' + attr.to_s + '?')
      else
        attr
      end
    end.compact
    @associations = self.class.associate.collect do |attr|
      a = {}
      attr.each_pair do |k,v|
        if self.class.method_defined?('_' + k.to_s + '?')
          a.merge!({k => v}) if self.send('_' + k.to_s + '?')
        else
          a.merge!({k => v})
        end
      end
      a unless a.blank?
    end.compact

    @nodes = []
    self.class.nodes.each do |node|
      if node.is_a? Hash
        node.each_pair do |k,v|
          conditional = v[0]
          conditional = conditional.to_proc if conditional.respond_to?(:to_proc) && conditional.present?
          conditional = conditional.is_a?(Proc) ? instance_exec(&conditional) : true

          @nodes << {k => v[1]} if conditional
        end
      else
        @nodes << node
      end
    end
  end

  def single?
    if instance_variable_defined?(:@single)
      @single
    else
      true
    end
  end

  def method_missing(method_sym,*args,&block)
    @caller.send(method_sym) if @caller
  end

  attr_reader :attributes,:associations, :custom_methods, :nodes

  private

  def self.build_boolean(args,&block)
    args.each do |arg|
      if arg.is_a?(Symbol)
        define_method('_' + arg.to_s + '?', &block)
      elsif arg.is_a?(Hash)
        build_boolean(arg.keys,&block)
      end
    end if block_given?
  end
end