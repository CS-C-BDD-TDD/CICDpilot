# Initialize logs

INSTRUMENTATION_PATH = ENV['INSTRUMENTATION_PATH'] || 'log'

AuthenticationLogger = Logger.new("#{INSTRUMENTATION_PATH}/authentication-#{Rails.env}.log")

if Rails.configuration.log_level == :debug
  LifecycleLogger = Logger.new("#{INSTRUMENTATION_PATH}/lifecycle-#{Rails.env}.log")

  class ActiveRecord::Base
    include Auditable::Instrumentation
  end

  EnvLogger = Logger.new("#{INSTRUMENTATION_PATH}/env-#{Rails.env}.log")
  EnvLogger.debug(ENV)
    
end

if Rails.env=='development'
  console = ActiveSupport::Logger.new($stdout)
  console.formatter = Rails.logger.formatter
  console.level = Rails.logger.level

  # Turning this off because it is interfering with the output for the big:migration task
  Rails.logger.extend(ActiveSupport::Logger.broadcast(console))   
end

TOULogger = Logger.new("#{INSTRUMENTATION_PATH}/tou-#{Rails.env}.log")
SearchLogger = Logger.new("#{INSTRUMENTATION_PATH}/search-#{Rails.env}.log")
WeatherMapLogger = Logger.new("#{INSTRUMENTATION_PATH}/weather-map-#{Rails.env}.log")
ExceptionLogger = Logger.new("#{INSTRUMENTATION_PATH}/exceptions-#{Rails.env}.log")
ReplicationLogger = Logger.new("#{INSTRUMENTATION_PATH}/replication-#{Rails.env}.log")
UploadLogger = Logger.new("#{INSTRUMENTATION_PATH}/uploads-#{Rails.env}.log")
RequestLogger= Logger.new("#{INSTRUMENTATION_PATH}/requests-#{Rails.env}.log")
AmqpReceiverLogger = Logger.new("#{INSTRUMENTATION_PATH}/amqp-receiver-#{Rails.env}.log")
DatabasePoolLogger = Logger.new("#{INSTRUMENTATION_PATH}/database-pool-#{Rails.env}.log")
AisStatisticLogger = Logger.new("#{INSTRUMENTATION_PATH}/ais-statistics-#{Rails.env}.log")
AvpValidationLogger = Logger.new("#{INSTRUMENTATION_PATH}/avp-validation-#{Rails.env}.log")
SolrIndexingLogger = Logger.new("#{INSTRUMENTATION_PATH}/solr-indexing-#{Rails.env}.log")
DisseminationServiceLogger = Logger.new("#{INSTRUMENTATION_PATH}/dissemination-service-#{Rails.env}.log")
TransferErrorLogger = Logger.new("#{INSTRUMENTATION_PATH}/transfer-error-#{Rails.env}.log")
PendingMarkingLogger = Logger.new("#{INSTRUMENTATION_PATH}/pending-marking-#{Rails.env}.log")
