namespace :amqp_receiver do
  def truncate_pid
    begin
      File.open(@pidfile, ::File::WRONLY) {} if File.exists?(@pidfile)
    rescue
      AmqpReceiverLogger.error("[AMQP Receiver] Failed to truncate #{@pidfile}")
    end
  end

  def write_pid
    begin
      File.open(@pidfile, ::File::WRONLY) {
          |f|
        f.write("#{Process.pid}")
      } if File.exists?(@pidfile)
      at_exit { truncate_pid }
    rescue Errno::EEXIST
      check_pid
      retry
    end
  end

  def check_pid
    case pid_status
      when :running, :not_owned
        AmqpReceiverLogger.error("[AMQP Receiver] A server is already running. Check #{@pidfile}")
        exit(1)
      when :dead
        truncate_pid
    end
  end

  def pid_status
    return :exited unless File.exists?(@pidfile)
    pid = ::File.read(@pidfile).to_i
    return :dead if pid == 0
    Process.kill(0, pid) # check process status
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end

  def trap_signals
    # Trap ^C
    Signal.trap('INT') do
      @shut_down_requested = true
      @retry_mutex.synchronize do
        @retry_cv.signal
      end
      if @msg_handler.present?
        @msg_handler.shutdown
      end
      if @dissemination_service.present?
        @dissemination_service.shutdown_dq_processor
      end
    end

    # Trap `Kill `
    Signal.trap('TERM') do
      @shut_down_requested = true
      @retry_mutex.synchronize do
        @retry_cv.signal
      end
      if @msg_handler.present?
        @msg_handler.shutdown
      end
      if @dissemination_service.present?
        @dissemination_service.shutdown_dq_processor
      end
    end
  end

  task :run => :environment do |t, args|
    if Setting.USE_AMQP_RECEIVER
      def init_dissemination_service
        if AppUtilities.is_ecis_dms_1c_arch?
          if Setting.DISSEMINATION_QUEUE_PROCESSOR_FREQUENCY_IN_MINUTES.to_i > 0
            dissemination_service_options = {
                dissemination_cleanup_frequency:
                    "#{Setting.DISSEMINATION_QUEUE_PROCESSOR_FREQUENCY_IN_MINUTES}m",
                dq_processor_logger_prefix: '[Dissemination Queue Processor] '
            }
            @dissemination_service =
                DisseminationService.new(dissemination_service_options)
          else
            @dissemination_service = DisseminationService.new
          end
        else
          @dissemination_service = nil
        end
      end

      def init_msg_handler
        msg_handler_options = {
            jndi_props_file: @jndi_props_file,
            amqp_topic_lookup_name: @amqp_topic_lookup_name,
            amqp_jar_list: @amqp_jar_list,
            amqp_tls_config: @amqp_tls_config,
            dissemination_service: @dissemination_service
        }
        @msg_handler = AmqpReceiverMsgHandler.new(msg_handler_options)

        unless @msg_handler.present? && @msg_handler.jndi_valid?
          AmqpReceiverLogger.error('[AMQP Receiver] AMQP JNDI Init FAILED. Aborting receiver startup.')
          return false
        end
        true
      end

      def init_msg_processor
        if Setting.USE_AMQP_RECEIVER_MESSAGE_PROCESSOR
          msg_processor_options = {
              amqp_max_xml_processors: Setting.AMQP_MAX_XML_MESSAGE_PROCESSORS || 5,
              amqp_max_json_processors: Setting.AMQP_MAX_JSON_MESSAGE_PROCESSORS || 5,
              amqp_logger: AmqpReceiverLogger,
              amqp_receiver_msg_handler: @msg_handler,
              amqp_logger_prefix: '[AMQP Receiver Message Processor] '
          }
          @msg_processor = AmqpProcessingService.new(msg_processor_options)
        else
          @msg_processor = nil
        end
      end

      def start_dq_processor
        if @dissemination_service.present? &&
            Setting.DISSEMINATION_QUEUE_PROCESSOR_FREQUENCY_IN_MINUTES.to_i > 0
          @dissemination_service.start_dq_processor
        end
      end

      env_vars_to_merge = [
          'AMQP_RECEIVER_APP_PATH',
          'AMQP_RECEIVER_PID',
          'AMQP_RECEIVER_JAR_PATH',
          'AMQP_RECEIVER_JNDI_PROPS_FILE',
          'AMQP_RECEIVER_JNDI_TOPIC_LOOKUP',
          'AMQP_RECEIVER_HEALTH_CHECK_INTERVAL',
          'AMQP_RECEIVER_KEYSTORE_LOCATION',
          'AMQP_RECEIVER_TRUSTSTORE_LOCATION',
          'AMQP_RECEIVER_KEYSTORE_PASSWORD',
          'AMQP_RECEIVER_TRUSTSTORE_PASSWORD'
      ]
      @amqp_settings = AmqpUtilities.get_amqp_settings(env_vars_to_merge)
      @amqp_receiver_app_path =
          File.expand_path(@amqp_settings['AMQP_RECEIVER_APP_PATH'] ||
                               File.dirname(__FILE__) + '/../..')
      @pidfile = File.expand_path(@amqp_settings['AMQP_RECEIVER_PID'] ||
                                      '/var/run/amqp-receiver.pid',
                                  @amqp_receiver_app_path)
      @amqp_jar_path =
          File.expand_path(@amqp_settings['AMQP_RECEIVER_JAR_PATH'] ||
                               @amqp_receiver_app_path + '/lib/amqp',
                           @amqp_receiver_app_path)
      @amqp_jar_list = Dir.glob(File.join(@amqp_jar_path, '*.jar')) || []
      @jndi_props_file =
          File.expand_path(@amqp_settings['AMQP_RECEIVER_JNDI_PROPS_FILE'] ||
                               ENV['RAILS_JNDI_PROPS'] ||
                               '/etc/cyber-indicators/config/jndi.properties',
                           @amqp_receiver_app_path)
      @amqp_topic_lookup_name =
          @amqp_settings['AMQP_RECEIVER_JNDI_TOPIC_LOOKUP']
      @health_check_interval =
          @amqp_settings['AMQP_RECEIVER_HEALTH_CHECK_INTERVAL'] || 600
      @amqp_tls_config = {
          'javax.net.ssl.keyStore' =>
              @amqp_settings['AMQP_RECEIVER_KEYSTORE_LOCATION'],
          'javax.net.ssl.trustStore' =>
              @amqp_settings['AMQP_RECEIVER_TRUSTSTORE_LOCATION'],
          'javax.net.ssl.keyStorePassword' =>
              @amqp_settings['AMQP_RECEIVER_KEYSTORE_PASSWORD'],
          'javax.net.ssl.trustStorePassword' =>
              @amqp_settings['AMQP_RECEIVER_TRUSTSTORE_PASSWORD']
      }
      @shut_down_requested = false
      @retry_mutex = Mutex.new
      @retry_cv = ConditionVariable.new

      check_pid
      write_pid
      trap_signals

      init_dissemination_service
      exit(1) unless init_msg_handler
      init_msg_processor
      start_dq_processor

      until @shut_down_requested
        msg_and_status = @msg_handler.receive_message(@health_check_interval)
        if msg_and_status[:conn_failed]
          @retry_mutex.synchronize do
            # Wait for 60 seconds to try again only if the connection and/or
            # subscription completely failed to be acquired. If another
            # exception occurred or the the timeout merely expired with no
            # message received, we will try again immediately.
            @retry_cv.wait(@retry_mutex, 60)
          end
        elsif msg_and_status[:msg].present?
          if Setting.USE_AMQP_RECEIVER_MESSAGE_PROCESSOR
            pending_msg_id, is_stix_xml =
                @msg_handler.persist_message_to_db(msg_and_status[:msg])
            if pending_msg_id >= 0
              @msg_handler.acknowledge_message(msg_and_status[:msg])
              if pending_msg_id > 0
                @msg_processor.schedule_processor(pending_msg_id, is_stix_xml)
              end
            end
          elsif @msg_handler.process_message(msg_and_status[:msg])
            @msg_handler.acknowledge_message(msg_and_status[:msg])
          else
            # Wait for 60 seconds to try again if there was an exception while
            # validating the user credentials received. Force the logging of
            # database pool stats because this indicates that a database
            # connection issue is likely to be present.
            DatabasePoolLogging.update_and_log_info(0, true)
            @retry_mutex.synchronize do
              @retry_cv.wait(@retry_mutex, 60)
            end
          end
        end
      end
    end
  end
end
