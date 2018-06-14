require 'singleton'

class AmqpReplication
  include Singleton

  def initialize
    init_paths
    init_amqp_connection
    connection
  end


  def init_paths
    env_vars_to_merge = [
        'AMQP_SENDER_APP_PATH',
        'AMQP_SENDER_JAR_PATH',
        'AMQP_SENDER_JNDI_PROPS_FILE',
        'AMQP_SENDER_JNDI_TOPIC_LOOKUP',
        'AMQP_SENDER_KEYSTORE_LOCATION',
        'AMQP_SENDER_TRUSTSTORE_LOCATION',
        'AMQP_SENDER_KEYSTORE_PASSWORD',
        'AMQP_SENDER_TRUSTSTORE_PASSWORD'
    ]
    @amqp_settings = AmqpUtilities.get_amqp_settings(env_vars_to_merge)
    @amqp_sender_app_path =
        File.expand_path(@amqp_settings['AMQP_SENDER_APP_PATH'] || Rails.root)
    @amqp_jar_path = File.expand_path(@amqp_settings['AMQP_SENDER_JAR_PATH'] ||
                                          Rails.root + '/lib/amqp',
                                      @amqp_sender_app_path)
    @amqp_jar_list = Dir.glob(File.join(@amqp_jar_path, '*.jar')) || []
    @jndi_props_file =
        File.expand_path(@amqp_settings['AMQP_SENDER_JNDI_PROPS_FILE'] ||
                             ENV['RAILS_JNDI_PROPS'] ||
                             '/etc/cyber-indicators/config/jndi.properties',
                         @amqp_sender_app_path)
    @amqp_topic_lookup_name =
        @amqp_settings['AMQP_SENDER_JNDI_TOPIC_LOOKUP']
    @amqp_tls_config = {
        'javax.net.ssl.keyStore' =>
            @amqp_settings['AMQP_SENDER_KEYSTORE_LOCATION'],
        'javax.net.ssl.trustStore' =>
            @amqp_settings['AMQP_SENDER_TRUSTSTORE_LOCATION'],
        'javax.net.ssl.keyStorePassword' =>
            @amqp_settings['AMQP_SENDER_KEYSTORE_PASSWORD'],
        'javax.net.ssl.trustStorePassword' =>
            @amqp_settings['AMQP_SENDER_TRUSTSTORE_PASSWORD']
    }
  end

  def init_amqp_connection
    conn_options = {
        jndi_props_file: @jndi_props_file,
        amqp_jar_list: @amqp_jar_list,
        amqp_tls_config: @amqp_tls_config,
        amqp_logger: ReplicationLogger,
        amqp_logger_prefix: '[AMQP Sender] ',
        amqp_topic_lookup_name: @amqp_topic_lookup_name,
        amqp_client_id: Setting.SYSTEM_GUID.gsub(/:/, '-') + '-SENDER'
    }
    @amqp_connection = AmqpUtilities.new(conn_options)
  end

  def publish_message(msg_data, string_props={})
    @amqp_connection.publish_message(msg_data, string_props)
  end

  def connection
    @amqp_connection.get_connection
  end

  def connection_valid?
    @amqp_connection.connection_valid?
  end

  def disconnect
    @amqp_connection.disconnect
  end

end

