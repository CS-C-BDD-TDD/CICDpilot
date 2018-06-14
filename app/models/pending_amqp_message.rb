class PendingAmqpMessage < ActiveRecord::Base
  self.table_name = 'pending_amqp_messages'

  def message_data=(message_data)
    write_attribute(:message_data, message_data.force_encoding('UTF-8'))
    write_attribute(:is_stix_xml, message_data.include?('stix:STIX_Package'))
  end

  def message_data
    read_attribute(:message_data).force_encoding('UTF-8')
  end

  alias_method :get_text, :message_data

  def string_props=(string_props)
    write_attribute(:string_props, string_props.to_json)
    if string_props[:repl_type].present?
      write_attribute(:repl_type, string_props[:repl_type])
    end
    if string_props[:transfer_category].present?
      write_attribute(:transfer_category, string_props[:transfer_category])
    end
  end

  def string_props
    ActiveSupport::JSON.decode(read_attribute(:string_props)).symbolize_keys
  end

  # Set the last updated timestamp on the PendingAmqpMessage to the
  # current time and increment the attempt counter.
  def log_failed_attempt
    self.last_attempted = Time.now
    self.increment(:attempt_count)
  end
end
