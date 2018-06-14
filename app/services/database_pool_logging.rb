# A utility service class to support better database pool logging in general and
# troubleshooting of database pool management issues specifically inside
# threads.
class DatabasePoolLogging

  # The cached database pool stats hash; initialized with only a nil timestamp.
  @@pool_stats = {timestamp: nil}

  # Update the @@pool_stats class variable if the timestamp in the current
  # pool_stats hash is more than max_stale_seconds old. If an update was
  # performed because the cached stats were stale, it returns the updated
  # pool_stats hash. If the hash cached as the class variable was not stale,
  # it returns nil. This method collects similar database pool stats as the
  # ActiveRecord::Base.connection_pool.stat method added in Rails v5.1.
  def self.update_pool_stats(max_stale_seconds=0)
    begin
      if max_stale_seconds == 0 || @@pool_stats.blank? ||
          @@pool_stats[:timestamp].blank? ||
          Time.now.to_i - @@pool_stats[:timestamp].to_i > max_stale_seconds

        pool =
            ActiveRecord::Base.connection_pool.instance_eval { @available }
        connections =
            ActiveRecord::Base.connection_pool.instance_eval { @connections }

        @@pool_stats = {
            size: ActiveRecord::Base.connection_pool.size,
            connections: connections.size,
            busy: connections.count { |c| c.in_use? && c.owner.alive? },
            dead: connections.count { |c| c.in_use? && !c.owner.alive? },
            idle: connections.count { |c| !c.in_use? },
            num_waiting: pool.num_waiting,
            checkout_timeout: ActiveRecord::Base.connection_pool.checkout_timeout,
            timestamp: Time.now
        }
        @@pool_stats # Return updated database pool stats.
      else
        nil # No update was necessary.
      end
    rescue Exception => e
      DatabasePoolLogger.error("Exception caught while updating database pool stats. Previous database pool stats: #{ @@pool_stats }. Exception: #{ e.message } Backtrace: #{ e.backtrace}")
      @@pool_stats # Return the previous cached database pool stats even
      # though they are stale since we might have a database or database pool
      # management issue and we want to know what the state of the database
      # pools was when it was last in a known reliable state. The error
      # message in the logs generated here and the timestamp provide the
      # means to detect that stale database pool stats have been returned to
      # the caller.
    end
  end

  # Get the database pool stats either after an update if the cached stats
  # are older than max_stale_seconds or get the cached stats.
  def self.pool_stats(max_stale_seconds=0)
    update_pool_stats(max_stale_seconds) || @@pool_stats
  end

  # Log an info message to the database pool log containing message_text and
  # append the database pool stats, forcing an update if the cached stats are
  # more than max_stale_seconds old. This method is disabled and returns
  # immediately unless Setting.DATABASE_POOL_LOGGING_ENABLED is true.
  def self.log_info(message_text, max_stale_seconds=0)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED
    DatabasePoolLogger.info("#{ message_text }, stats: #{ pool_stats(max_stale_seconds) }")
  end

  # Log an error message to the database pool log containing message_text and
  # append the database pool stats, forcing an update if the cached stats are
  # more than max_stale_seconds old. This method is disabled and returns
  # immediately unless Setting.DATABASE_POOL_LOGGING_ENABLED is true.
  def self.log_error(message_text, max_stale_seconds=0)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED
    DatabasePoolLogger.error("#{ message_text }, stats: #{ pool_stats(max_stale_seconds) }")
  end

  # Log a debug message to the database pool log containing message_text and
  # append the database pool stats, forcing an update if the cached stats are
  # more than max_stale_seconds old. This method is disabled and returns
  # immediately unless Setting.DATABASE_POOL_LOGGING_ENABLED is true.
  def self.log_debug(message_text, max_stale_seconds=0)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED
    DatabasePoolLogger.debug("#{ message_text }, stats: #{ pool_stats(max_stale_seconds) }")
  end

  # Log a warn message to the database pool log containing message_text and
  # append the database pool stats, forcing an update if the cached stats are
  # more than max_stale_seconds old. This method is disabled and returns
  # immediately unless Setting.DATABASE_POOL_LOGGING_ENABLED is true.
  def self.log_warn(message_text, max_stale_seconds=0)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED
    DatabasePoolLogger.warn("#{ message_text }, stats: #{ pool_stats(max_stale_seconds) }")
  end

  # Log an info message to the database pool log with the database pool
  # stats but only if the cached stats are more than max_stale_seconds old.
  # Unlike the log_info message, which will log regardless of whether the
  # stats were updated because they were stale, this method only logs if the
  # stats were updated because the cache was stale.
  # This method is disabled and returns immediately unless
  # Setting.DATABASE_POOL_LOGGING_ENABLED is true.
  def self.update_and_log_info(max_stale_seconds=0, force=false)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED || force
    db_pool_stats = update_pool_stats(max_stale_seconds)
    return if db_pool_stats.nil?
    DatabasePoolLogger.info("Database Pool Stats: #{ db_pool_stats }")
  end

  # Connection Pool Management for Threads

  # Threads are a potential problem area for database pool management in
  # rails. When an exception is thrown in a thread, it is useful to log the
  # status of the database pools when the exception occurred with the
  # information in the exception itself. This method implements this
  # capability by logging an error message to the database pool log with the
  # exception message and backtrace, class name, line number, and database
  # pool stats. This method is disabled and returns immediately unless
  # Setting.DATABASE_POOL_LOGGING_ENABLED is true.
  def self.log_thread_error(exception, class_name, line_num)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED
    message_text = "Exception caught within a thread on line #{ line_num } " +
        "of #{ class_name}: Exception: #{ exception.message } " +
        "Backtrace: #{ exception.backtrace} " +
        "Database Pool Stats: #{pool_stats(0)}"
    DatabasePoolLogger.error("#{ message_text }")
  end

  # Threads are a potential problem area for database pool management in
  # rails. It is sometimes useful to log the status of the database pools
  # upon entering a new thread as a troubleshooting tool. This method
  # implements this capability by logging an info message to the database pool
  # log with the class name, line number, and database pool stats. This
  # method is disabled and returns immediately unless both
  # Setting.DATABASE_POOL_LOGGING_ENABLED and
  # Setting.DATABASE_POOL_LOGGING_ON_THREAD_ENTRY_ENABLED are true.
  def self.log_thread_entry(class_name, line_num)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED &&
        Setting.DATABASE_POOL_LOGGING_ON_THREAD_ENTRY_ENABLED
    message_text = "Entering a thread on line #{ line_num } " +
        "of #{ class_name}: Database Pool Stats: #{pool_stats(0)}"
    DatabasePoolLogger.info("#{ message_text }")
  end

  # Threads are a potential problem area for database pool management in
  # rails. It is sometimes useful to log the status of the database pools
  # upon exiting a thread as a troubleshooting tool. This method
  # implements this capability by logging an info message to the database pool
  # log with the class name, line number, and database pool stats. This
  # method is disabled and returns immediately unless both
  # Setting.DATABASE_POOL_LOGGING_ENABLED and
  # Setting.DATABASE_POOL_LOGGING_ON_THREAD_EXIT_ENABLED are true.
  def self.log_thread_exit(class_name, line_num)
    return unless Setting.DATABASE_POOL_LOGGING_ENABLED &&
        Setting.DATABASE_POOL_LOGGING_ON_THREAD_EXIT_ENABLED
    message_text = "Exiting a thread on line #{ line_num } " +
        "of #{ class_name}: Database Pool Stats: #{pool_stats(0)}"
    DatabasePoolLogger.info("#{ message_text }")
  end
end