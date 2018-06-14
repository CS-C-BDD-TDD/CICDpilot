class AmqpReceiverMsgHandler
  def initialize(options)
    @jndi_props_file = options[:jndi_props_file]
    @amqp_jar_list = options[:amqp_jar_list]
    @amqp_tls_config = options[:amqp_tls_config]
    @amqp_topic_lookup_name = options[:amqp_topic_lookup_name]
    @dissemination_service = options[:dissemination_service]
    @connection = nil
    @subscriber = nil
    @sess = nil
    init_amqp_connection
  end

  def init_amqp_connection
    conn_options = {
        jndi_props_file: @jndi_props_file,
        amqp_jar_list: @amqp_jar_list,
        amqp_tls_config: @amqp_tls_config,
        amqp_logger: AmqpReceiverLogger,
        amqp_logger_prefix: '[AMQP Receiver] ',
        amqp_topic_lookup_name: @amqp_topic_lookup_name,
        amqp_client_id: Setting.SYSTEM_GUID.gsub(/:/, '-') + '-RECEIVER',
        amqp_ssl_version: 'TLSv1_2',
        amqp_verify_mode: 0,
        dissemination_service: @dissemination_service
    }
    @amqp_connection = AmqpUtilities.new(conn_options)
  end

  def jndi_valid?
    @amqp_connection.jndi_valid?
  end

  def get_connection
    @amqp_connection.get_connection
  end

  def connection_valid?
    @amqp_connection.connection_valid?
  end

  def get_properties_hash(serialized_message)
    return {} unless serialized_message.present?
    return serialized_message.string_props if serialized_message.is_a?(PendingAmqpMessage)
    props = {}
    serialized_message.get_property_names.each { |key|
      props[key.to_sym] = serialized_message.get_string_property(key)
    }
    props
  end

  def log_amqp_msg_item(message_text, msg_item, log_msg_item_prefix)
    @amqp_connection.log_debug("[#{log_msg_item_prefix} #{message_text}] #{msg_item}") if message_text.present? && msg_item.present?
  end

  def log_amqp_msg(msg_data, string_props={}, log_msg_item_prefix)
    log_amqp_msg_item('Event Message', string_props[:Event],
                      log_msg_item_prefix)
    log_amqp_msg_item('Replicated Data', msg_data, log_msg_item_prefix)
    log_amqp_msg_item('Replication Type', string_props[:repl_type],
                      log_msg_item_prefix)
    log_amqp_msg_item('Source Feed Value', string_props[:src_feed],
                      log_msg_item_prefix)
    log_amqp_msg_item('Transfer Category', string_props[:transfer_category],
                      log_msg_item_prefix)
    log_amqp_msg_item('Final Tag', string_props[:final].to_s,
                      log_msg_item_prefix)
    log_amqp_msg_item('Dissemination Labels',
                      string_props[:dissemination_labels].to_s,
                      log_msg_item_prefix)
    log_amqp_msg_item('Dissemination Feed',
                      string_props[:dissemination_feed].to_s,
                      log_msg_item_prefix)
    log_amqp_msg_item('API Key', string_props[:api_key],
                      log_msg_item_prefix)
  end

  # This method will persist the AMQP message to the database as a
  # PendingAmqpMessage but not actually process it. The text message body and
  # the AMQP string properties will be stored so they can be processed
  # separately by the processing service. The method returns an two-element
  # array with the first element containing the id of the record in the database
  # if successful, 0 if the AMQP message itself is unsupported and should simply
  # be acknowledged and skipped, or -1 if this message failed to be persisted to
  # the database (e.g., because the connection to the DBMS is down) and should
  # not be acknowledged. The second element in the array is a boolean
  # indicating whether the message data received was a STIX XML file or not.
  def persist_message_to_db(serialized_message)
    return [0, false]  unless serialized_message.present?

    begin
      @amqp_connection.log_info('[Received AMQP Message]')
      # Extract the replicated data payload and string properties.
      repl_data, string_props = extract_amqp_msg(serialized_message)

      begin
        pending_amqp_msg = PendingAmqpMessage.new
        pending_amqp_msg.message_data = repl_data
        pending_amqp_msg.string_props = string_props
        pending_amqp_msg.save!
        [pending_amqp_msg.id, pending_amqp_msg.is_stix_xml]
      rescue Exception => e
        @amqp_connection.log_error("Error while persisting the message received via AMQP to the database: #{e.message}")
        @amqp_connection.log_debug("Error while persisting the message received via AMQP to the database (backtrace): #{e.backtrace}")
        @amqp_connection.log_warn('Errors while persisting the message received via AMQP to the database are typically due to database connection issues so this file will not be acknowledged.')
        [-1, false]
      end
    rescue Exception => e
      @amqp_connection.log_error("Error while deserializing the message received via AMQP: #{e.message}")
      @amqp_connection.log_debug("Error while deserializing the message received via AMQP (backtrace): #{e.backtrace}")
      [0, false]
    end
  end

  def extract_string_props(serialized_message)
    # The string properties from the AMQP message.
    string_props = get_properties_hash(serialized_message)

    # Decode the Dissemination Labels from JSON to a hash if received.
    string_props[:dissemination_labels] =
        ActiveSupport::JSON.decode(string_props[:dissemination_labels]) if
        string_props[:dissemination_labels].present? &&
            string_props[:dissemination_labels].is_a?(String)
    # Decode the Dissemination Feed from JSON to a hash if received.
    string_props[:dissemination_feed] =
        ActiveSupport::JSON.decode(string_props[:dissemination_feed]) if
        string_props[:dissemination_feed].present? &&
            string_props[:dissemination_feed].is_a?(String)
    # Decode the final flag back to a boolean if received.
    string_props[:final] = string_props[:final] == 'true' if
        string_props[:final].present? && string_props[:final].is_a?(String)

    string_props
  end

  def extract_amqp_msg(serialized_message)
    if serialized_message.is_a?(PendingAmqpMessage)
      log_msg_item_prefix = 'AMQP Message'
    else
      log_msg_item_prefix = 'Received'
    end

    # The data payload from the AMQP message.
    msg_data = serialized_message.get_text.to_s
    # The string properties from the AMQP message.
    string_props = extract_string_props(serialized_message)
    # Log the data payload and string properties from the AMQP message.
    log_amqp_msg(msg_data, string_props, log_msg_item_prefix)

    # Return the extracted message data payload and string properties.
    [msg_data, string_props]
  end

  def process_message(serialized_message, user_sync_mutex=nil)
    return true unless serialized_message.present?

    begin
      # Extract the replicated data payload and string properties.
      repl_data, string_props = extract_amqp_msg(serialized_message)

      @amqp_connection.log_info('[Validating API User Credentials]')

      begin
        # When processing AMQP messages in parallel, use a mutex so that the
        # user record does not have its last login time updated by multiple
        # threads at the same time. Otherwise, the AMQP messages are received
        # serially so only one will be processed at a time.
        user_sync_mutex.lock unless user_sync_mutex.nil?

        user = @amqp_connection.get_user_from_api_credentials(string_props[:api_key],
                                                              string_props[:api_key_hash])
      rescue Exception => e
        @amqp_connection.log_error("Error while validating the user credentials received via AMQP: #{e.message}")
        @amqp_connection.log_debug("Error while validating the user credentials received via AMQP (backtrace): #{e.backtrace}")
        @amqp_connection.log_warn('Errors while validating the user credentials received via AMQP are typically due to database connection issues so this file will not be acknowledged.')
        return false
      ensure
        # Ensure the mutex is unlocked if we are using one for this method
        # call. Ruby will ensure this block runs even if the rescue block
        # above returns false due to an exception.
        user_sync_mutex.unlock unless user_sync_mutex.nil?
      end

      if user.present?
        @amqp_connection.log_info("api_key: #{string_props[:api_key]}, username:#{user.username}")
        User.current_user = user
      else
        @amqp_connection.log_error('[Invalid User]')
        return true
      end

      if repl_data.present?
        store_options = {
            src_feed: string_props[:src_feed],
            transfer_category: string_props[:transfer_category],
            repl_type: string_props[:repl_type],
            dissemination_labels: string_props[:dissemination_labels],
            dissemination_feed: string_props[:dissemination_feed],
            final: string_props[:final]
        }
        if [OriginalInput::XML_DISSEMINATION_ISA_FILE,
            OriginalInput::XML_DISSEMINATION_AIS_FILE,
            OriginalInput::XML_DISSEMINATION_CISCP_FILE].include?(store_options[:transfer_category])
          unless @amqp_connection.disseminate_xml_from_amqp(repl_data, user,
                                                            store_options)
            @amqp_connection.log_warn('Dissemination failed so this file will not be acknowledged.')
            return false
          end
        elsif store_options[:transfer_category] ==
            OriginalInput::XML_DISSEMINATION_TRANSFER
          unless @amqp_connection.disseminate_file_from_amqp(repl_data, user,
                                                             store_options)
            @amqp_connection.log_warn('Dissemination failed for all feeds so this file will not be acknowledged.')
            return false
          end
        elsif %w(publish stix_forward).include?(store_options[:repl_type])
          @amqp_connection.store_amqp_replicated_xml(repl_data, user,
                                                     store_options)
        elsif store_options[:repl_type] == 'ais_statistic_forward'
          @amqp_connection.store_amqp_replicated_ais_statistic(repl_data)
        elsif repl_data.exclude?('stix:STIX_Package') &&
            [Setting.FLARE_IN_REPL_TYPE,
             Setting.FLARE_OUT_REPL_TYPE].include?(store_options[:repl_type])
          @amqp_connection.parse_and_store_amqp_ais_statistic_flare(store_options[:repl_type],
                                                                    repl_data)
        else
          # The default action if a valid repl_type was not sent as an AMQP
          # string property is to check if it is STIX XML and proceed as an
          # uploaded file if it is STIX XML or log an error otherwise.
          @amqp_connection.store_amqp_replicated_xml(repl_data, user,
                                                     store_options)
        end
      end
    rescue Exception => e
      @amqp_connection.log_error("Error while processing the message received via AMQP: #{e.message}")
      @amqp_connection.log_debug("Error while processing the message received via AMQP (backtrace): #{e.backtrace}")
    end
    true
  end

  def receive_message(timeout_in_sec=0)
    @amqp_connection.receive_message(timeout_in_sec * 1000)
  end

  def acknowledge_message(message)
    @amqp_connection.acknowledge_message(message)
  end

  def shutdown
    @amqp_connection.disconnect
  end
end
