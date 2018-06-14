class Replication < ActiveRecord::Base
  after_create -> { version = Rails.configuration.version }

  def get(*args)
    opts = args.last.is_a?(Hash) ? args.pop : {}
    url = opts.delete("url") || self.url
    uri = URI.parse(url)
    request_uri = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
    get = Net::HTTP::Get.new(request_uri)
    get["api_key"] = api_key
    get["api_key_hash"] = api_key_hash
    content_type = opts.delete("Content-type") || opts.delete("Content-Type") || 'application/json'
    get["Content-type"] = content_type
    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_PEER) do |https|
        https.request(get)
      end
    body = response.body
    @response_code = response.code.to_i
    JSON.parse body
  end

  def success?
    @response_code ||= 0
    200 <= @response_code && @response_code < 300
  end

  def skip
    ReplicationLogger.info("[Replication][skip][#{self.id}] Skipping replication to #{url}. Data is already present on remote end ...")
  end

  def send_data(data, *args)
    if AppUtilities.is_amqp_sender?
      begin
        ReplicationLogger.info('[Replication Model] Using AMQP')

        amqp = AmqpReplication.instance
        ReplicationLogger.info('[Replication Model] AMQP Object initialized')

        string_props = {
            'Event' => "Upload Replication Event from: #{AppUtilities.is_ciap? ? 'CIAP' : 'ECIS'}",
            'api_key' => self.api_key.to_s,
            'api_key_hash' => self.api_key_hash.to_s,
            'repl_type' => self.repl_type.to_s
        }

        # Add the transfer_category as an AMQP string property if passed as
        # an argument.
        if args[0].present? && args[0]['transfer_category'].present?
          string_props['transfer_category'] = args[0]['transfer_category']

          if [OriginalInput::XML_DISSEMINATION_ISA_FILE,
              OriginalInput::XML_DISSEMINATION_AIS_FILE,
              OriginalInput::XML_DISSEMINATION_CISCP_FILE,
              OriginalInput::XML_DISSEMINATION_TRANSFER].include?(string_props['transfer_category'])
            string_props['dissemination_labels'] =
                args[0]['dissemination_labels']
            string_props['dissemination_feed'] =
                args[0]['dissemination_feed'] unless
                string_props['transfer_category'] ==
                    OriginalInput::XML_DISSEMINATION_TRANSFER
          end
        end

        if args[0].present? && args[0]['final'].present?
          string_props['final'] = args[0]['final']
        end

        if amqp.publish_message(data, string_props)
          ReplicationLogger.info('[Replication Model] Replication Finished')
          true
        else
          ReplicationLogger.debug('[Replication Model] Failed to replicate the file through AMQP')
          false
        end
      rescue Exception => e
        ReplicationLogger.error("[Replication Model] Failed to replicate the file through AMQP, error #{e.message}")
        ReplicationLogger.debug("[Replication Model] Failed to replicate the file through AMQP, backtrace #{e.backtrace}")
        false
      end
    else
      opts = args.last.is_a?(Hash) ? args.pop : {}
      url = opts.delete("url") || self.url
      post_opts = opts

      begin
        ReplicationLogger.info("[Replication][send_data][#{self.id}] Starting replication to #{url} ...")
        uri = URI.parse(url)
        request_uri = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
        post = Net::HTTP::Post.new(request_uri)
        post["api_key"] = api_key
        post["api_key_hash"] = api_key_hash
        content_type = post_opts.delete('Content-type') ||
                       post_opts.delete('Content-Type') ||
                       'application/json'
        post["Content-type"] = content_type
        post_opts.each_pair do |key,value|
          post[key] = value
        end
        post.body = data
        ReplicationLogger.info("[Replication][send_data] api_key: #{post["api_key"]}, api_key_hash: #{post['api_key_hash']}, content-type: #{post['Content-type']}")
        ReplicationLogger.debug("[Replication][send_data] request body: #{post.body}")
        response = Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: true,
          verify_mode: OpenSSL::SSL::VERIFY_PEER) do |https|
            https.request(post)
          end

        if 200 <= response.code.to_i && response.code.to_i < 300
          self.last_status = 'OK'
          ReplicationLogger.info("[Replication][send_data][#{self.id}]response.code: #{response.code}, response.body: #{response.body}")
          save
          ReplicationLogger.info("[Replication][send_data][#{self.id}] done.")
          return true
        else
          self.last_status = 'FAILED'
          ReplicationLogger.info("[Replication][send_data][#{self.id}] ID: #{self.id} response.code: #{response.code}, response.body: #{response.body}")
          save
          ReplicationLogger.info("[Replication][send_data][#{self.id}] done.")
          return false
        end
      rescue Exception => e
        ReplicationLogger.info("[Replication][send_data][#{self.id}] failed due to an internal error.  Please check the exceptions log.")
        ExceptionLogger.debug("exception: #{e},message: #{e.message},backtrace: #{e.backtrace}")
        self.last_status = 'EXCEPTION'
        save
        ReplicationLogger.info("[Replication][send_data][#{self.id}] done.")
        false
      end
    end
  end

  def test
    begin
      test_path = ENV['TEST_PATH']||'cyber-indicators/users/current'
      uri = URI.parse url
      test_url = ["#{uri.scheme}:/","#{uri.host}:#{uri.port}",test_path].join('/')
      uri = URI.parse test_url
      host = uri.host
      port = uri.port
      http = Net::HTTP.new host,port
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      get = Net::HTTP::Get.new uri.request_uri
    rescue Exception => e
      puts "Error configuring replication: #{e}"
      self.last_status = 'EXCEPTION'
      save
      return false
    end

    get["api_key"] = api_key 
    get["api_key_hash"] = api_key_hash

    begin
      puts "Testing connection to #{test_url}..."
      response = http.request(get)
    rescue Errno::ECONNREFUSED => e
      puts("Cannot connect to #{uri}.")
      self.last_status = 'FAILED - COULD NOT CONNECT'
      save
      return false
    rescue Exception => e
      puts("Exception: #{e}")
      self.last_status = 'EXCEPTION'
      save
      return false
    end
    
    if 200 <= response.code.to_i && response.code.to_i < 300
      puts "success: #{response.message}"
      self.last_status = response.message
      save
      replication_user = JSON.parse(response.body)
      unless replication_user['machine']
        print "The connection was successful.  However, the user on the remote server does not\nhave machine set to true, so this replication will fail.  Please fix this on\nthe remote server and run this test again.\n".red
      end
      return true
    else
      puts "response message: #{response.message}"
      self.last_status = 'FAILED - INVALID RESPONSE'
      save
      return false
    end
  end

  def test_post
    if repl_type == 'weathermap'
      send_data("\{\}")
      return
    end
    
    if repl_type == 'public_release_indicators'
      indicator = Indicator.new title: 'replication-test-indicator',description:'indicator-for-test'
      send_data(indicator.to_json,{'Content-type' => 'application/json'})
      return
    end

    if repl_type == 'heatmap'
      send_data(File.read(ENV['HEATMAP']||'script/test_heatmap_upload.png'),
                {'Content-type'=>'image/png','organization-token'=>'TEST'})
    end
  end
end
