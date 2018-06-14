module ActiveModel::Serialization
  def serializable_hash(options = nil)
    options ||= {}

    attribute_names = attributes.keys
    if only = options[:only]
      attribute_names &= Array(only).map(&:to_s)
    elsif except = options[:except]
      attribute_names -= Array(except).map(&:to_s)
    end

    hash = {}
    attribute_names.each { |n| hash[n] = read_attribute_for_serialization(n) }

    Array(options[:methods]).each { |m| hash[m.to_s] = send(m) if respond_to?(m) }

    serializable_add_includes(options) do |association, records, opts|
      val = if records.respond_to?(:to_ary)
              records.to_ary.map { |a| a.serializable_hash(opts) }
            else
              records.serializable_hash(opts)
            end

      if name = opts[:as]
        hash[name] = val
      else
        hash[association.to_s] = val
      end
    end

    hash
  end
end