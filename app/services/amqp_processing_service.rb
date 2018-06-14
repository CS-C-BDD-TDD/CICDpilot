require 'rufus-scheduler'

class AmqpProcessingService
  def initialize(options)
    @amqp_max_xml_processors = options[:amqp_max_xml_processors] || 5
    @amqp_max_json_processors = options[:amqp_max_json_processors] || 5
    @xml_scheduler = Rufus::Scheduler.new(max_work_threads:
                                              @amqp_max_xml_processors)
    @json_scheduler = Rufus::Scheduler.new(max_work_threads:
                                            @amqp_max_json_processors)
    @logger_prefix = options[:amqp_logger_prefix] || ''
    @logger = options[:amqp_logger]
    @amqp_receiver_msg_handler = options[:amqp_receiver_msg_handler]
    @user_sync_mutex = Mutex.new
    @scheduled_ids_mutex = Mutex.new
    @scheduled_ids = []
    schedule_pending_from_db
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

  def schedule_pending_from_db
    pending_msg_ids = PendingAmqpMessage.pluck(:id, :is_stix_xml)
    pending_msg_ids.each { |pending_msg_id, is_stix_xml|
      self.schedule_processor(pending_msg_id, is_stix_xml)
    }
  end

  def call_processor(pending_msg_id, job, time)
    begin
      DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
      begin
        log_info("AMQP message processing job #{job.id} called at #{time} to process pending AMQP message #{pending_msg_id}")
        pending_amqp_msg = PendingAmqpMessage.find_by(id: pending_msg_id)
      rescue Exception => e
        log_error("Error loading pending AMQP message #{pending_msg_id} from database in AMQP message processing job #{job.id}: #{e.message}")
        return
      end
      if pending_amqp_msg.nil?
        log_warn("AMQP message processing job #{job.id} exiting due to nonexistent pending AMQP message #{pending_msg_id}")
      elsif @amqp_receiver_msg_handler.process_message(pending_amqp_msg, @user_sync_mutex)
        log_info("AMQP message processing job #{job.id} successfully processed pending AMQP message #{pending_msg_id}")
        # Remove the PendingAmqpMessage from the database since it has been
        # processed.
        begin
          pending_amqp_msg.destroy!
        rescue Exception => e
          log_error("Error removing successfully processed pending AMQP message #{pending_msg_id} from the database: #{e.message}")
        end
      else
        log_error("AMQP message processing job #{job.id} failed to process pending AMQP message #{pending_msg_id}")
        # Log the failed attempt on the PendingAmqpMessage record.
        begin
          pending_amqp_msg.log_failed_attempt
          pending_amqp_msg.save!
        rescue Exception => e
          log_error("Error logging failed processing attempt in the pending AMQP message #{pending_msg_id} database record: #{e.message}")
        end
      end
    rescue Exception => e
      DatabasePoolLogging.log_thread_error(e, self.class.to_s, __LINE__)
    ensure
      unless Setting.DATABASE_POOL_ENSURE_THREAD_CONNECTION_CLEARING == false
        begin
          ActiveRecord::Base.clear_active_connections!
        rescue Exception => e
          DatabasePoolLogging.log_thread_error(e, self.class.to_s,
                                               __LINE__)
        end
      end
      # Remove the id from the list of pending ids. Whether processing
      # succeeded or failed, this processor job is ending. If the pending
      # message is still in the database, processing will be attempted again
      # in the future via the schedule_pending_from_db method,
      @scheduled_ids_mutex.synchronize {
        @scheduled_ids.delete(pending_msg_id)
      }
    end
    DatabasePoolLogging.log_thread_exit(self.class.to_s, __LINE__)
  end

  def schedule_processor(pending_msg_id, is_stix_xml)
    # Check if this id has already been scheduled in case a new AMQP message
    # is received before the pending messages are scheduled from the database.
    @scheduled_ids_mutex.synchronize {
      # If this id has already been scheduled, stand down by returning.
      return if @scheduled_ids.include?(pending_msg_id)
      # This processor will handle this id so add it to the array.
      @scheduled_ids << pending_msg_id
    }

    # Create a new processor instance for this pending message id.
    processor = AmqpMessageProcessor.new(pending_msg_id, self)
    # Schedule the new processor to start in one second (or until a vacant
    # worker is available).
    if is_stix_xml
      @xml_scheduler.in('1s', processor)
    else
      @json_scheduler.in('1s', processor)
    end
  end

  # This is a Rufus Scheduler handler class used to simplify creating jobs.
  # Rufus will call the "call" method when it is ready to start the job.
  class AmqpMessageProcessor
    def initialize(pending_msg_id, processing_service)
      @pending_msg_id = pending_msg_id
      @processing_service = processing_service
    end

    # Rufus will call this method to start the job.
    def call(job, time)
      # Hand things off to the "call_processor" method on the processing
      # service to do the real work.
      @processing_service.call_processor(@pending_msg_id, job, time)
    end
  end
end
