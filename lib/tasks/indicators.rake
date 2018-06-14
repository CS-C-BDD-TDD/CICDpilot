namespace :indicators do
  task :release => :environment do
    class Hash
      def deep_reject(&blk)
        self.dup.deep_reject!(&blk)
      end

      def deep_reject!(&blk)
        self.each do |k, v|
          v.deep_reject!(&blk) if v.is_a?(Hash)
          self.delete(k) if blk.call(k, v)
        end
      end

    end


    log_path = ENV['LOG_PATH'] || "log" 
    log_file ="#{log_path}/indicators-release-#{Rails.env}.log"
    ReleaseLogger = Logger.new("#{log_path}/indicators-release-#{Rails.env}.log")
    ReleaseLogger.info("Starting ...")

    def usage
      puts %{Usage: SOURCE_URL=<https://url.to.get.indicators> \
SOURCE_API_KEY=<src_api_key> \
SOURCE_API_KEY_HASH=<src_api_key_hash> \
TARGET_URL=<https://url.to.send.indicators> \
TARGET_API_KEY=<tgt_api_key> \
TARGET_API_KEY_HASH=<tgt_api_key_hash> \
TGT_SUPPORTS_BULK_POST=true|false \
SSL_VERIFY=true|false \
LOG_PATH=/tmp \
rake indicators:release}
      puts %{
Description: This tool may be used to copy indicators between Cyber Indicators systems.

Note: The target user account must be a machine user.

Note: You must supply a LOG_PATH or else the log will not be visible.
}
      exit(1)
    end

    log_json = ENV["LOG_JSON"] || false
    source_url = ENV['SOURCE_URL'] || usage
    source_api_key = ENV['SOURCE_API_KEY'] || usage 
    source_api_key_hash = ENV['SOURCE_API_KEY_HASH'] || usage 
    target_url = ENV['TARGET_URL'] || usage
    target_api_key = ENV['TARGET_API_KEY'] || usage 
    target_api_key_hash = ENV['TARGET_API_KEY_HASH'] || usage 
    terminate_on_exceptions = ENV['TERMINATE_ON_EXCEPTIONS'] || "true"
    target_supports_bulk_post = ENV['TARGET_SUPPORTS_BULK_POST'] || "true"

    begin
    source_uri = URI.parse(source_url)
    source_host = source_uri.host
    source_port = source_uri.port
    source_http = Net::HTTP.new(source_host,source_port)
    source_http.use_ssl = true
    source_http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    get = Net::HTTP::Get.new(source_uri.request_uri)
    rescue
      puts %{Error configuring the source connection.  Are you sure #{ENV['SOURCE_URL']} is formatted correctly?
  You must supply:  https://<base-url>:<port>/cyber-indicators/<index-route>
  For example:      https://server.domain.com:8443/cyber-indicators/public_indicators
  or:      https://server.domain.com:8443/cyber-indicators/weather_map_indicators
}
   end
    get["Accept"] = "application/json"
    get["api_key"] = source_api_key
    get["api_key_hash"] = source_api_key_hash
   
    puts "Writing output to log file: #{log_file}"
    ReleaseLogger.info "[client] Reading from #{ENV['SOURCE_URL']}"
    ReleaseLogger.info "[client] Sending to #{ENV['TARGET_URL']}"
    

    begin
      ReleaseLogger.info("[client] Fetching data ...")
      response = source_http.request(get) 
    rescue Errno::ECONNREFUSED => e
      ReleaseLogger.info("[source] Cannot connect to #{source_uri}. Is it up?")
    rescue Exception => e
      ReleaseLogger.info("[source] An exception occurred fetching indicators.")
      ReleaseLogger.info("         Exception: #{e}")
      ReleaseLogger.info("         Backtrace: ")
      e.backtrace.each { |line| ReleaseLogger.info line }

      exit_code = 1
      if terminate_on_exceptions=="true"
        exit exit_code
      end
    end

    begin
      ReleaseLogger.info("[source] Parsing data ...")
      json = JSON.parse(response.body)
      if log_json == "true"
        ReleaseLogger.info("[source] JSON: #{json}")
      end
    rescue Exception => e
      ReleaseLogger.info("[source] An exception occurred parsing JSON.")
      ReleaseLogger.info("         Exception: #{e}")
      ReleaseLogger.info("         Backtrace: ")
      e.backtrace.each { |line| ReleaseLogger.info line }
      ReleaseLogger.info("         Response body: #{response.body}") if response
      exit_code = 1
      if terminate_on_exceptions=="true"
        exit exit_code
      end
    end

    ReleaseLogger.info("[source] Extracting source system GUID ...")
    begin
    indicators = (json||{})["indicators"]
    metadata = (json||{})["metadata"]
    rescue
      ReleaseLogger.info("[source] Response received does not meet JSON interface.  Re-run with: LOG_JSON=true rake indicators:release . Inspect the JSON in this log.")
    end
    if (metadata||{})["system_guid"].blank? 
      ReleaseLogger.info("[source] Source system is missing System GUID")
      ReleaseLogger.debug("[source] JSON: #{json}")
      exit 1 
    end 
    ReleaseLogger.info("[source] Source system GUID is #{metadata["system_guid"]}") 
    data = {metadata: metadata,indicators: indicators}

    response = nil
    target_uri = URI.parse(target_url)
    target_host = target_uri.host
    target_port = target_uri.port
    target_http = Net::HTTP.new(target_host,target_port)
    target_http.use_ssl = true
    target_http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    post = Net::HTTP::Post.new(target_uri.request_uri)
    post["Accept"] = "application/json"
    post["api_key"] = target_api_key
    post["api_key_hash"] = target_api_key_hash
    post['Content-Type']='application/json'

    observable_types = %w{dns_record domain email_message file http_session address mutex network_connection registry uri}
    keys_to_reject = %w{id address_value}

    if target_supports_bulk_post != "true"
      indicators.each do |indicator|
        begin
          indicator["system_guid"] = metadata["system_guid"]
          observables = indicator["observables_attributes"] 
          observables.map! { |observable| observable.deep_reject { |k,v| v.blank? } }
          indicator_json = indicator.to_json
          
          post.body = indicator_json
          if log_json == "true"
            ReleaseLogger.info("[target] JSON: #{indicator.to_json}")
          end
          response = target_http.request(post)
          ReleaseLogger.info("[target] writing indicator: #{indicator["guid"]} status: #{response.message} code: #{response.code}")
        rescue Exception => e
          ReleaseLogger.info("[target] An exception occurred during the transfer.")
          ReleaseLogger.debug("  Exception: #{e}")
          ReleaseLogger.info("   Backtrace: ")
          e.backtrace.each { |line| ReleaseLogger.info line }
          exit_code = 1
          if terminate_on_exceptions=="true"
            exit exit_code
          end
        end
      end
    end

    if target_supports_bulk_post == "true"
      begin
        post.body = data.to_json
        ReleaseLogger.info("[target] Sending data (indicators.length: #{indicators.length}) ...")
        response = target_http.request(post)
        ReleaseLogger.info("[target] status: #{response.message} code: #{response.code}")
        body = (response.body || "").to_json
        ReleaseLogger.info("[target] response.body: #{body}")
      rescue Net::ReadTimeout => e
        ReleaseLogger.info("[target] Cannot connect to #{target_uri}. Timed out. Is it up?")
      rescue Errno::ECONNREFUSED => e
        ReleaseLogger.info("[target] Cannot connect to #{target_uri}. Is it up?")
      rescue Exception => e
        ReleaseLogger.info("[target] An exception occurred during the transfer.")
        ReleaseLogger.debug("  Exception: #{e}")
        ReleaseLogger.info("   Backtrace: ")
        e.backtrace.each { |line| ReleaseLogger.info line }
        exit_code = 1
        if terminate_on_exceptions=="true"
          exit exit_code
        end
      end
    end

    ReleaseLogger.info("Finished (exit #{exit_code.presence || 0})")
    exit exit_code.presence || 0
  end

end
