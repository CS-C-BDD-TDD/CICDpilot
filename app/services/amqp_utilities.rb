class AmqpUtilities
  def initialize(options)
    @jndi_props_file = options[:jndi_props_file]
    @amqp_jar_list = options[:amqp_jar_list]
    @amqp_tls_config = options[:amqp_tls_config]
    @logger = options[:amqp_logger]
    @logger_prefix = options[:amqp_logger_prefix] || ''
    @topic_lookup_name = options[:amqp_topic_lookup_name]
    @client_id = options[:amqp_client_id] || Setting.SYSTEM_GUID.gsub(/:/, '-')
    @ssl_version = options[:amqp_ssl_version]
    @verify_mode = options[:amqp_verify_mode]
    @dissemination_service = options[:dissemination_service]
    @connection = nil
    @connection_mutex = Mutex.new
    @is_disconnected = true
    @is_connection_disabled = false
    @subscriber = nil
    @subscriber_mutex = Mutex.new
    @is_subscriber_listening = false
    @sess = nil
    return unless init_default_ssl_context
    init_jndi
  end

  def log_info(message_text)
    @logger.info("#{ @logger_prefix }#{ message_text }")
  end

  def log_error(message_text)
    @logger.error("#{ @logger_prefix }#{ message_text }")
  end

  def log_debug(message_text)
    @logger.debug("#{ @logger_prefix }#{ message_text }")
  end

  def log_warn(message_text)
    @logger.warn("#{ @logger_prefix }#{ message_text }")
  end

  def jndi_valid?
    @inits.present?
  end

  def init_jndi
    log_info('AMQP JNDI Init')
    @inits = {}
    return unless load_java
    return unless init_java_tls_config
    load_jndi_props
  end

  def init_default_ssl_context
    log_info('AMQP Default SSLContext Init')
    begin
      OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] =
          @ssl_version if @ssl_version.present?
    rescue Exception => ex
      log_error("Error setting SSLContext default ssl_version to: #{@ssl_version}, error: #{ex.message}")
      return false
    end

    begin
      OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:verify_mode] =
          @verify_mode if @verify_mode.present?
      true
    rescue Exception => ex
      log_error("Error setting SSLContext default verify_mode to: #{@verify_mode}, error: #{ex.message}")
      false
    end
  end

  def init_java_tls_config
    begin
      prop_name = nil
      log_info('Setting Java keystore and truststore system properties.')
      @amqp_tls_config.each { |key, value|
        prop_name = key
        Java::JavaLang::System.set_property(prop_name, value)
      } if @amqp_tls_config.present?
      prop_name = nil
      log_info('Confirming Java keystore and truststore system properties were set as expected.')
      @amqp_tls_config.each { |key, value|
        prop_name = key
        unless Java::JavaLang::System.get_property(prop_name) == value
          log_error("Failed to set the '#{prop_name}' Java system property.")
          return false
        end
      } if @amqp_tls_config.present?
      log_info('Successfully set Java keystore and truststore system properties.')
      true
    rescue Exception => ex
      prop_name.present? ?
          log_error("Error setting the '#{prop_name}' Java system property: #{ex.message}") :
          log_error("Error setting Java system properties: #{ex.message}")
      false
    end
  end

  def load_java
    begin
      jf = nil
      require 'java'
      @amqp_jar_list.each do |jf|
        require jf
      end if @amqp_jar_list.present?
    rescue Exception => ex
      jf.present? ? log_error("Error requiring jar file: #{jf}, error: #{ex.message}") :
          log_error("Error requiring java, error: #{ex.message}")
      @inits = {}
      return false
    end

    begin
      # Check that required classes are available. If the jars were properly
      # required, the classes are loaded on first access so simply call the
      # name method, rescuing the exception if a class is not available and
      # returning false or true if all are available.
      Java::JavaxNaming::Context.name
      Java::JavaxNaming::InitialContext.name
      Java::JavaxJms::JMSException.name
      Java::JavaxJms::Session.name
      Java::JavaxJms::Message.name
      Java::JavaxJms::MessageConsumer.name
      Java::JavaxJms::MessageProducer.name
      Java::JavaLang::System.name
      true
    rescue Exception => ex
      log_error("Error importing java classes: #{ex.message}")
      @inits = {}
      false
    end
  end

  def load_jndi_props
    begin
      unless @jndi_props_file.present? && File.exists?(@jndi_props_file)
        log_error("JNDI properties file does not exist or is not readable: #{@jndi_props_file}")
        @inits = {}
        return false
      end

      env = Java::JavaUtil::Hashtable.new
      env.put(Java::JavaxNaming::Context::INITIAL_CONTEXT_FACTORY,
              'org.apache.qpid.jms.jndi.JmsInitialContextFactory')
      env.put(Java::JavaxNaming::Context::PROVIDER_URL, @jndi_props_file)

      properties = Java::JavaUtil::Properties.new
      instr = Java::JavaIo::FileInputStream.new(@jndi_props_file)
      properties.load(instr)

      @inits[:properties] = properties

      log_info("JNDI properties file loaded: #{@jndi_props_file}")
    rescue Exception => ex
      log_error("Error loading JNDI properties file: #{@jndi_props_file}, error: #{ex.message}")
      log_debug("Error loading JNDI properties file: #{@jndi_props_file}, backtrace: #{ex.backtrace}")
      @inits = {}
      return false
    end

    begin
      log_info('Loading JNDI initial context')
      @inits[:context] = Java::JavaxNaming::InitialContext.new(env)
    rescue Exception => ex
      log_error("Error loading JNDI initial context: #{ex.message}")
      log_debug("Error loading JNDI initial context (backtrace): #{ex.backtrace}")
      @inits = {}
      return false
    end

    begin
      log_info('Looking up properties from JNDI context')

      @inits[:topic] = @inits[:context].lookup(@topic_lookup_name)

      log_info("topic: #{ @inits[:topic].to_s }")

      @inits[:uname] = properties.get_property('queue.username')
      @inits[:pass] = properties.get_property('queue.password')

      factory_names = properties.get_property('queue.serverlist').to_s.strip
      log_info("factory names: #{ factory_names }")

      @inits[:factoryList] = factory_names.split(%r{\s+})
      true
    rescue Exception => ex
      log_error("Error looking up properties from JNDI context: #{ex.message}")
      @inits = {}
      false
    end
  end

  def get_connection
    @connection_mutex.synchronize do
      # Return nil if connection is disabled in order to expedite service
      # shutdown.
      if @is_connection_disabled
        log_info('Connection disabled because the service is shutting down.')
        return nil
      end
      # Return nil if JNDI initialization failed.
      return nil unless jndi_valid?
      # Return the existing connection if it is present, connected, not
      # failed, and not closed.
      return @connection if connection_valid?

      if @connection.present?
        log_info('Connection is not null and needs clean up.')
        disconnect
      end

      # Otherwise, try each and connect to the first available cluster server.
      @inits[:factoryList].each do |factory_name|
        # Return nil if connection is disabled in order to expedite service
        # shutdown.
        if @is_connection_disabled
          log_info('Connection disabled because the service is shutting down.')
          return nil
        end

        log_info("Factory Name: #{factory_name}")

        begin
          factory = @inits[:context].lookup(factory_name)
          log_info('URL: ' + factory.to_s)

          if @inits[:uname].present? && @inits[:pass].present?
            log_info('Connecting to DMS server using username and password authentication...')
            @connection = factory.create_connection(@inits[:uname], @inits[:pass])
          else
            log_info('Connecting to DMS server using client certificate authentication...')
            @connection = factory.create_connection
          end
          log_info('Successfully connected to DMS server')

          # Set a clientID
          @connection.set_client_id(@client_id)

          #if it has connection then set listener to monitor the connection
          # health, and reconnect if it disconnect
          @connection.set_exception_listener do |jms_exception|
            log_error('Error in connection: ' + jms_exception.get_message)
            if @connection.present?
              log_info('Attempting to close and restart connection in ExceptionListener.')
              @is_disconnected = true
              # Since we once had a connection but it subsequently failed,
              # try to recreate the connection immediately because another
              # server in the cluster may be available. This is merely an
              # active attempt to keep the connection alive. If the reconnect
              # fails, users of the connection will worry about how to handle
              # it when they actually use it so we do not check the results
              # here.
              get_connection
            else
              log_info('Connection is null in ExceptionListener, do not need to clean up')
              @is_disconnected = true
            end
          end

          if connection_valid?(true)
            # Return the connection immediately upon the first success.
            log_info("Connected to factory name: #{factory_name}")
            @is_disconnected = false
            return @connection
          else
            log_error("Failed to connect to factory name: #{factory_name}")
            @is_disconnected = true
            @connection = nil
          end
        rescue Exception => ex
          log_error("Error when connecting to factory name: #{factory_name}: #{ex.message}")
          @is_disconnected = true
          @connection = nil
        end
      end
    end

    # If we make it here without returning the connection earlier, we have
    # failed after trying each factory in the cluster list and return nil.
    log_error('Unable to connect to any AMQP server in the cluster')
    nil
  end

  def connection_valid?(ignore_is_disconnected_flag=false)
    # Return true if the connection is present and started.
    @connection.present? && !@connection.closed? && !@connection.failed? &&
        @connection.connected? && !@is_connection_disabled &&
        (ignore_is_disconnected_flag || !@is_disconnected)
  end

  def get_subscriber
    @subscriber_mutex.synchronize do
      begin
        if get_connection.present?
          # If @subscriber is not nil after the connection check that
          # potentially reestablished the connection and removed any old
          # subscribers in the process, return the existing subscriber.
          if @subscriber.present? && @is_subscriber_listening
            return @subscriber
          elsif @subscriber.present?
            log_info('Attempting to close the subscriber in order to restart it.')
            @subscriber.close
          end
          log_info('Creating connection session to receive replication via AMQP')
          @sess = @connection.create_session(false, Java::JavaxJms::Session::CLIENT_ACKNOWLEDGE)
          # Subscription name that the amqp server will know us by
          sub_name = @connection.get_client_id
          log_info("Creating a durable subscriber with subscription name: #{sub_name}")
          @subscriber = @sess.create_durable_subscriber(@inits[:topic], sub_name, nil, true)
          log_info("Created subscriber on topic #{@inits[:topic]} with subscription name #{sub_name}")
          @connection.start
          log_info('Started the Connection')
          @is_subscriber_listening = true
          return @subscriber
        end
      rescue Exception => e
        log_error("Failed setting up the subscriber to receive replication via AMQP, error: #{e.message}")
      end
    end
    nil
  end

  def receive_message(timeout_in_ms=0)
    if get_subscriber.present?
      begin
        log_info('Listening for the next message from the AMQP server...')
        { msg: @subscriber.receive(timeout_in_ms), conn_failed: false }
      rescue Java::JavaxJms::JMSException => jms_ex
        log_error("Error listening for an AMQP message, JMSException: #{jms_ex.get_message}")
        @is_subscriber_listening = false
        { msg: nil, conn_failed: false }
      rescue Exception => ex
        log_error("Error listening for an AMQP message: #{ ex }")
        @is_subscriber_listening = false
        { msg: nil, conn_failed: false }
      end
    else
      { msg: nil, conn_failed: true }
    end
  end

  def acknowledge_message(message)
    if message.present?
      begin
        log_info('Acknowledging message receipt with the AMQP server.')
        message.acknowledge
      rescue Java::JavaxJms::JMSException => jms_ex
        log_error("Error acknowledging AMQP message, JMSException: #{jms_ex.get_message}")
      rescue Exception => ex
        log_error("Error acknowledging AMQP message: #{ ex }")
      end
    end
  end

  def set_properties_from_hash(serialized_message, string_props={})
    if serialized_message.present? && string_props.present?
      # Set String Properties.
      string_props.each_pair { |key, value|
        log_debug("#{key}: #{value}")
        serialized_message.set_string_property(key, value.to_s)
      }
    end
  end

  def publish_message(msg_data, string_props={})
    begin
      if get_connection.present?
        log_info('Creating connection session to send replication via AMQP')
        sess = @connection.create_session(false, Java::JavaxJms::Session::AUTO_ACKNOWLEDGE)
        log_info("Creating a producer on topic: #{@inits[:topic]}")
        prod = sess.create_producer(@inits[:topic])
        log_info("Created a producer on topic: #{@inits[:topic]}")
        @connection.start
        log_info('Started the Connection')

        log_debug("Message Data:\n#{msg_data}")
        mess = sess.create_text_message(msg_data)

        # Set String Properties.
        log_debug('String Properties:')
        set_properties_from_hash(mess, string_props)

        log_info('Sending data...')
        prod.send(mess)
        log_info('Data sent')
        log_info('Closing producer session')
        sess.close
        log_info('Closed session')
        return true
      else
        log_debug('Failed to get a connection to publish via AMQP')
      end
    rescue Java::JavaxJms::JMSException => jms_ex
      log_debug("Failed to publish via AMQP, JMSException: #{jms_ex.message}")
    rescue Exception => e
      log_debug("Failed to publish via AMQP, error #{e.message}")
    end
    false
  end

  def shutdown
    # We cannot initiate shutdown if an attempt to connect in the
    # get_connection is in progress. Therefore, we flag that the connection is
    # disabled in order to expedite service shutdown by enabling the
    # get_connection method to potentially abort sooner as this flag is
    # checked before trying each server in the cluster and at the start of
    # the method. The connection_mutex synchronizes calls to get_connection
    # and shutdown to ensure mutual exclusion. Once all pending
    # get_connection calls are forced to return earlier or immediately, the
    # shutdown will begin.
    @is_connection_disabled = true
    @connection_mutex.synchronize do
      disconnect
    end
  end

  def disconnect
    log_info('Starting shutdown')
    # Close the connection
    if @connection.present?
      begin
        @connection.close
        log_info('Connection closed in disconnect call')
      rescue Java::JavaxJms::JMSException => jms_ex
        log_error("Error during connection close, JMSException: #{ jms_ex.get_message }")
      rescue Exception => ex
        log_error("Error during connection close: #{ ex }")
      ensure
        log_info('Set connection to nil')
        @connection = nil
        @sess = nil
        @subscriber = nil
      end
      log_info('Shutdown complete')
    end
  end

  def get_user_from_api_credentials(api_key, api_key_hash)
    unless api_key.present? && api_key_hash.present?
      log_debug('[no credentials specified]')
      return nil
    end
    user = Authentication::APIAuth.authenticate(api_key, api_key_hash)
    if !user
      log_debug("[invalid_api_key_or_api_key_hash] attempted with api_key: #{api_key}")
      return nil
    end
    if user.disabled_at.present?
      log_debug("[disabled] username: #{user.username}")
      return nil
    end
    if user.expired?
      log_debug("[expired] username: #{user.username}")
      return nil
    end
    user.logged_in_at = Time.now
    user.save
    user
  end

  def store_amqp_replicated_xml(uploaded_xml, amqp_user, options={})
    uploaded_file = UploadedFile.new
    if options[:repl_type].blank?
      log_info('Checking if the data received via AMQP replication is STIX XML')
      unless uploaded_file.is_stix?(uploaded_xml)
        log_error('Failed to store the data received via AMQP replication because the data is not STIX XML and a valid repl_type was not sent')
        return uploaded_file
      end
    end
    log_info('Storing the XML file received via AMQP replication as an UploadedFile')
    # Set the src_feed attribute on uploaded_file if it was received.
    uploaded_file.src_feed = options[:src_feed] if options[:src_feed].present?
    # Set the final attribute on uploaded_file if it was received.
    uploaded_file.final = options[:final] if options[:final].present?
    if uploaded_file.store_amqp_replicated_upload(uploaded_xml, amqp_user,
                                                  options)
      log_info("Successfully stored the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}")
    else
      error_msgs = uploaded_file.error_messages
      if error_msgs.present?
        log_error("[Errors] #{ error_msgs.collect(&:description).join(' ').to_s }")
      end
      log_error("Failed to store the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}")
    end
    uploaded_file
  end

  def store_pkg_id_mapping(uploaded_file, before_id, after_id)
    if before_id.present? && after_id.present?
      mapping =
          CiapIdMapping.find_or_create_by(before_id: before_id,
                                          after_id: after_id)
      if mapping.valid?
        oi = uploaded_file.original_inputs.first
        oi.ciap_id_mappings = [mapping]
        oi.save
        if oi.valid?
          log_info("Successfully stored the sanitized ID mappings received via AMQP replication for Uploaded File ID: #{uploaded_file.id}")
          true
        else
          error_msgs = mapping.error_messages
          if error_msgs.present?
            log_error("[Errors] #{ error_msgs.collect(&:description).join(' ').to_s }")
          end
          log_error("Failed to store the sanitized ID mappings received via AMQP replication for Uploaded File ID: #{uploaded_file.id}")
          false
        end
      else
        error_msgs = mapping.error_messages
        if error_msgs.present?
          log_error("[Errors] #{ error_msgs.collect(&:description).join(' ').to_s }")
        end
        log_error("Failed to store the sanitized ID mappings received via AMQP replication for Uploaded File ID: #{uploaded_file.id}")
        false
      end
    else
      true
    end
  end

  def disseminate_file_from_amqp(xml, amqp_user, options={})
    uploaded_file = store_amqp_replicated_xml(xml, amqp_user, options)

    if uploaded_file.valid? && @dissemination_service.present? &&
        options[:transfer_category] ==
            OriginalInput::XML_DISSEMINATION_TRANSFER &&
        options[:dissemination_labels].present? &&
        uploaded_file.original_inputs.active.present? &&
        uploaded_file.original_inputs.active.first.input_sub_category ==
            options[:transfer_category]

      if (Setting.SEND_FLARE_IDS || 'PARENT').upcase=='PARENT'
        store_pkg_id_mapping(uploaded_file,
                             options[:dissemination_labels]['original_stix_id'],
                             options[:dissemination_labels]['stix_id'])
      else
        store_amqp_replicated_id_mappings(uploaded_file, options[:dissemination_labels]['mapped_ids'])
      end

      log_info("Disseminating the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}")
      finished_feeds, failed_feeds =
          @dissemination_service.disseminate_file(uploaded_file.original_inputs.active.first, options[:dissemination_labels])
      if finished_feeds.present? && failed_feeds.blank?
        log_info("Successfully disseminated the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}\nFinished Feeds: #{finished_feeds.join(', ')}")
        true
      elsif finished_feeds.present? && failed_feeds.present?
        log_error("Partially disseminated the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}\nFailed Feeds: #{failed_feeds.join(', ')}\nFinished Feeds: #{finished_feeds.join(', ')}")
        true
      elsif finished_feeds.blank? && failed_feeds.present?
        log_error("Failed dissemination of the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}\nFailed Feeds: #{failed_feeds.join(', ')}")
        false
      else
        log_info("No applicable feeds are active to disseminate the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}")
        true
      end
    else
      true
    end
  end

  def disseminate_xml_from_amqp(xml, amqp_user, options={})
    uploaded_file = store_amqp_replicated_xml(xml, amqp_user, options)

    if uploaded_file.valid? && @dissemination_service.present? &&
        [
            OriginalInput::XML_DISSEMINATION_ISA_FILE,
            OriginalInput::XML_DISSEMINATION_AIS_FILE,
            OriginalInput::XML_DISSEMINATION_CISCP_FILE
        ].include?(options[:transfer_category]) &&
        options[:dissemination_feed].present? &&
        options[:dissemination_labels].present? &&
        uploaded_file.original_inputs.active.present? &&
        uploaded_file.original_inputs.active.first.input_sub_category ==
            options[:transfer_category]

      if (Setting.SEND_FLARE_IDS || 'PARENT').upcase=='PARENT'
        store_pkg_id_mapping(uploaded_file,
                             options[:dissemination_labels]['original_stix_id'],
                             options[:dissemination_labels]['stix_id'])
      else
        store_amqp_replicated_id_mappings(uploaded_file, options[:dissemination_labels]['mapped_ids'])
      end
      log_info("Disseminating the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}")
      finished_feeds, failed_feeds =
          @dissemination_service.disseminate_xml_to_feed(uploaded_file.original_inputs.active.first, options[:dissemination_feed], options[:dissemination_labels])
      if finished_feeds.present? && failed_feeds.blank?
        log_info("Successfully disseminated the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id} to Feed: #{finished_feeds.first}")
        # Dissemination was successful so the AMQP message should be
        # acknowledged.
        true
      elsif finished_feeds.blank? && failed_feeds.present?
        log_error("Failed dissemination of the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id} to Feed: #{failed_feeds.first}")
        # Dissemination failed so the AMQP message should not be acknowledged.
        false
      else
        log_info("No applicable feeds are active to disseminate the XML file received via AMQP replication as Uploaded File ID: #{uploaded_file.id}")
        # There are no active feeds to receive this file so the AMQP message
        # should be acknowledged since dissemination was technically successful.
        true
      end
    else
      # If the file cannot be uploaded, the AMQP message should still be
      # acknowledged because sending the file again is unlikely to resolve this
      # issue since the user check already required the database connection to
      # be valid to get this far. The file likely has a problem at this point.
      true
    end
  end

  def store_amqp_replicated_ais_statistic(ais_statistics_json)
    log_info('Storing the JSON received via AMQP replication as an AisStatistic')
    ais_statistics, system_logs =
        AisStatistic.store_amqp_replicated_ais_statistics(ais_statistics_json)
    if ais_statistics.present?
      ais_statistics.each { |ais_statistic|
        if ais_statistic.present? && ais_statistic.valid?
          log_info("Successfully stored the JSON received via AMQP replication as AIS Statistic ID: #{ais_statistic.guid}")
        elsif ais_statistic.present?
          log_error("[Errors] #{ ais_statistic.errors.to_s }")
          log_error("Failed to store the JSON received via AMQP replication as AIS Statistic ID: #{ais_statistic.guid}")
        else
          log_error('Failed to store the JSON received via AMQP replication as an AIS Statistic')
        end
      }
    end
    if system_logs.present?
      system_logs.each { |system_log|
        if system_log.present? && system_log.valid?
          log_info("Successfully stored the JSON received via AMQP replication as System Log ID: #{system_log.id}")
        elsif system_log.present?
          log_error("[Errors] #{ system_log.errors.to_s }")
          log_error("Failed to store the JSON received via AMQP replication as System Log ID: #{system_log.guid}")
        else
          log_error('Failed to store the JSON received via AMQP replication as a System Log')
        end
      }
    end

    [ais_statistics, system_logs]
  end

  def parse_and_store_amqp_ais_statistic_flare(repl_type, flare_json)
    log_info('Storing the JSON received from flare via AMQP replication as an AisStatistic')
    ais_statistics, system_logs = AisStatistic.parse_and_store_amqp_ais_statistics_flare(repl_type, flare_json)
    if ais_statistics.present?
      ais_statistics.each { |ais_statistic|
        if ais_statistic.present? && ais_statistic.valid?
          log_info("Successfully stored the JSON received via AMQP replication as AIS Statistic ID: #{ais_statistic.guid}")
        elsif ais_statistic.present?
          log_error("[Errors] #{ ais_statistic.errors.to_s }")
          log_error("Failed to store the JSON received via AMQP replication as AIS Statistic ID: #{ais_statistic.guid}")
        else
          log_error('Failed to store the JSON received via AMQP replication as an AIS Statistic')
        end
      }
    end
    if system_logs.present?
      system_logs.each { |system_log|
        if system_log.present? && system_log.valid?
          log_info("Successfully stored the JSON received via AMQP replication as System Log ID: #{system_log.id}")
        elsif system_log.present?
          log_error("[Errors] #{ system_log.errors.to_s }")
          log_error("Failed to store the JSON received via AMQP replication as System Log ID: #{system_log.guid}")
        else
          log_error('Failed to store the JSON received via AMQP replication as a System Log')
        end
      }
    end

    [ais_statistics, system_logs]
  end

  def store_amqp_replicated_id_mappings(uploaded_file, ciap_id_mappings)
    if ciap_id_mappings.present?
      transaction_status = true

      ActiveRecord::Base.transaction do
        mappings = []
        ciap_id_mappings.each do |before_id,after_id|
          if transaction_status
            mapping =
              CiapIdMapping.find_or_create_by(before_id: before_id,
                                              after_id: after_id)
            if mapping.valid?
              mappings << mapping
            else
              transaction_status = false
            end
          end
        end

        if transaction_status
          oi = uploaded_file.original_inputs.active.first
          oi.ciap_id_mappings = mappings
          oi.save
          if oi.valid?
            log_info("Successfully stored the sanitized ID mappings received via AMQP replication for Uploaded File ID: #{uploaded_file.id}")
          else
            error_msgs = mapping.error_messages
            if error_msgs.present?
              log_error("[Errors] #{ error_msgs.collect(&:description).join(' ').to_s }")
            end
            log_error("Failed to store the sanitized ID mappings received via AMQP replication for Uploaded File ID: #{uploaded_file.id}")
            raise ActiveRecord::Rollback
          end
        else
          error_msgs = mapping.error_messages
          if error_msgs.present?
            log_error("[Errors] #{ error_msgs.collect(&:description).join(' ').to_s }")
          end
          log_error("Failed to store the sanitized ID mappings received via AMQP replication for Uploaded File ID: #{uploaded_file.id}")
          raise ActiveRecord::Rollback
        end
        transaction_status
      end
    else
      true
    end
  end

  def self.get_amqp_settings(env_vars_to_merge=[])
    catalina_home = ENV['CATALINA_HOME'] || '/usr/share/tomcat7'

    amqp_settings = {
        'AMQP_SENDER_KEYSTORE_LOCATION' =>
            "#{catalina_home}/keystore/cacerts",
        'AMQP_SENDER_KEYSTORE_PASSWORD' =>
            Base64.decode64("Y2hhbmdlaXQ=\n"),
        'AMQP_SENDER_TRUSTSTORE_LOCATION' =>
            "#{catalina_home}/keystore/cacerts",
        'AMQP_SENDER_TRUSTSTORE_PASSWORD' =>
            Base64.decode64("Y2hhbmdlaXQ=\n"),
        'AMQP_SENDER_JNDI_TOPIC_LOOKUP' =>
            'senderTopicLookup',
        'AMQP_RECEIVER_KEYSTORE_LOCATION' =>
            "#{catalina_home}/keystore/cacerts",
        'AMQP_RECEIVER_KEYSTORE_PASSWORD' =>
            Base64.decode64("Y2hhbmdlaXQ=\n"),
        'AMQP_RECEIVER_TRUSTSTORE_LOCATION' =>
            "#{catalina_home}/keystore/cacerts",
        'AMQP_RECEIVER_TRUSTSTORE_PASSWORD' =>
            Base64.decode64("Y2hhbmdlaXQ=\n"),
        'AMQP_RECEIVER_JNDI_TOPIC_LOOKUP' =>
            'receiverTopicLookup'
    }

    env_vars_to_merge.each { |var_name|
      # Override the defaults with environment variable values.
      amqp_settings[var_name] =
          ENV[var_name] if ENV[var_name].present? &&
          %w(<REDACTED> <DEFAULT>).exclude?(ENV[var_name])
    }

    amqp_settings
  end
end
