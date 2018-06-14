require 'net/sftp'
require 'stringio'
require 'json'
require 'stix'
require 'rufus-scheduler'

class DisseminationService
  def initialize(options={})
    @config =
        YAML.load_file(options[:disseminate_yml_path] ||
                           ENV['RAILS_DISSEMINATE_YAML'] ||
                                 'config/disseminate.yml')
    @feeds = YAML.load_file(options[:disseminate_feeds_yml_path] ||
                                ENV['RAILS_DISSEMINATE_FEEDS_YAML'] ||
                                'config/disseminate_feeds.yml').
        select { |key, value| value['active'].to_s.downcase == 'true' }
    # MODE can be either 'API', 'SFTP', or 'BOTH'
    @mode = @config['MODE']
    @sftp = nil
    @sftp_mutex = Mutex.new
    @logger = options[:stdout_logging] == true ?
        StdOutLogger : DisseminationServiceLogger
    @logger_prefix = options[:dissemination_service_logger_prefix] || ''
    if options[:dissemination_cleanup_frequency].present?
      @wait_between_runs = options[:dissemination_cleanup_frequency]
      @dq_scheduler = Rufus::Scheduler.new
      @dq_logger_prefix = options[:dq_processor_logger_prefix] || ''
      @dq_running_job_mutex = Mutex.new
      @dq_running_job_cv = ConditionVariable.new
      @dq_shutdown_requested = false
    else
      @dq_scheduler = nil
    end
  end

  class StdOutLogger
    class <<self
      def puts_log_msg(message_text)
        puts message_text
      end

      alias_method(:info, :puts_log_msg)
      alias_method(:error, :puts_log_msg)
      alias_method(:debug, :puts_log_msg)
      alias_method(:warn, :puts_log_msg)
    end
  end

  def log_info(message_text, dq_logger_prefix='')
    @logger.info("#{ @logger_prefix }#{ dq_logger_prefix }#{ message_text }")
  end

  def log_error(message_text, dq_logger_prefix='')
    @logger.error("#{ @logger_prefix }#{ dq_logger_prefix }#{ message_text }")
  end

  def log_debug(message_text, dq_logger_prefix='')
    @logger.debug("#{ @logger_prefix }#{ dq_logger_prefix }#{ message_text }")
  end

  def log_warn(message_text, dq_logger_prefix='')
    @logger.warn("#{ @logger_prefix }#{ dq_logger_prefix }#{ message_text }")
  end

  def connect_to_sftp
    @sftp_mutex.synchronize {
      begin
        if @config['FLARE_SERVER_SSH_KEY_PATH'].present?
          @sftp = Net::SFTP.start(@config['FLARE_SERVER'],
                                  @config['FLARE_SERVER_USERNAME'],
                                  {keys: [@config['FLARE_SERVER_SSH_KEY_PATH']]})
        else
          @sftp = Net::SFTP.start(@config['FLARE_SERVER'],
                                  @config['FLARE_SERVER_USERNAME'])
        end
      rescue
        @sftp = nil
      end
    }
  end

  def write_sftp_file(file, contents, reconnected=false)
    succeed = true
    begin
      io = StringIO.new(contents)
      @sftp_mutex.synchronize {
        @sftp.upload!(io, file)
      }
    rescue Exception => e
      if e.message == 'connection closed by remote host' && !reconnected
        connect_to_sftp
        if @sftp.nil?
          succeed = false
        else
          write_sftp_file(file, contents, true)
        end
      else
        succeed = false
      end
    end
    succeed
  end

  def write_api_file(contents, feed)
    begin
      uri = URI.parse(@config['FLARE_API_URI'])
      uri += "?collection=#{feed}"
      # If this is the sanitized mappings file, replace the URI with /forward
      if feed=='JSON'
        uri += 'forward'
      end
      request_uri = uri.query ? "#{uri.path}?#{uri.query}" : uri.path
      post = Net::HTTP::Post.new(request_uri)
      post['Content-Type'] = 'application/xml'
      post.body = contents
      response =
          Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                          verify_mode: OpenSSL::SSL::VERIFY_PEER) do |https|
            https.request(post)
          end

      if 200 <= response.code.to_i && response.code.to_i < 300
        true
      else
        false
      end
    rescue Exception => e
      ExceptionLogger.debug("exception: #{e},message: #{e.message},backtrace: #{e.backtrace}")
      false
    end
  end

  def write_file(file, contents, feed)
    # If MODE is 'API', or 'SFTP', then failure is based upon whether that
    # specific function fails.  If MODE is 'BOTH', then only the result of
    # sending via API matters.  In this case, SFTP could fail and if API
    # succeeds, then the result is a success.  This is because in this case,
    # the SFTP portion is for our testing purposes, and is not being used for
    # actual sending to FLARE.
    if @mode == 'SFTP' || @mode == 'BOTH'
      succeed = write_sftp_file(file, contents)
    end
    if @mode == 'API' || @mode == 'BOTH'
      succeed = write_api_file(contents, feed)
    end
    succeed
  end

  def disseminate_to_feed(xml, oi_id, stix_id, mapping, date, ts, feed_key,
                          feed, finished_feeds, sanitized_mappings,
                          disseminated_on, create_queue_records,
                          failed_feeds)
    if xml.present?
      file_log_description =
          feed['profile'] == 'CISCP' ? 'CISCP' : 'fully sanitized'
      feed_key ||= feed['feed_key']
      if write_file(feed['directory']+'/'+stix_id+'_'+ts+'.xml', xml,
                    feed['feed'])
        disseminated_on << feed_key
        log_info("Sent STIX ID=#{stix_id} on #{feed_key} feed")
        sanitized_mappings << mapping if mapping.present?
        AisStatistic.log_dissemination_success(stix_id, feed_key, "Successfully sent #{ file_log_description } file to feed #{feed_key}")
        finished_feeds << feed_key
      else
        log_error("Problem sending STIX ID=#{stix_id} on #{feed_key} feed")
        AisStatistic.log_dissemination_failure(stix_id, "Failed to send #{ file_log_description } file to feed #{feed_key}")
        failed_feeds << feed_key
        create_queue_records << {
            original_input_id: oi_id,
            finished_feeds: finished_feeds.join(','),
            updated: date
        } unless create_queue_records.nil?
        return false
      end
    else
      log_warn("No XML content to write to #{feed['directory']}")
    end
    true
  end

  def disseminate_to_isa_feeds(xml_isa, oi_id, stix_id, mapping, date, ts,
                               finished_feeds, sanitized_mappings,
                               disseminated_on, create_queue_records,
                               failed_feeds)
    isa_feeds = @feeds.select { |key, feed|
      feed['profile'] == 'ISA' && finished_feeds.exclude?(key)
    }
    isa_feeds.each { |key, feed|
      return false unless disseminate_to_feed(xml_isa, oi_id, stix_id, mapping,
                                              date, ts, key, feed,
                                              finished_feeds,
                                              sanitized_mappings,
                                              disseminated_on,
                                              create_queue_records,
                                              failed_feeds)
    }
    true
  end

  def disseminate_to_ais_feeds(xml_ais, oi_id, stix_id, mapping, date, ts,
                               finished_feeds, sanitized_mappings,
                               disseminated_on, create_queue_records,
                               failed_feeds)
    ais_feeds = @feeds.select { |key, feed|
      feed['profile'] == 'AIS' && finished_feeds.exclude?(key)
    }
    ais_feeds.each { |key, feed|
      return false unless disseminate_to_feed(xml_ais, oi_id, stix_id, mapping,
                                              date, ts, key, feed,
                                              finished_feeds,
                                              sanitized_mappings,
                                              disseminated_on,
                                              create_queue_records,
                                              failed_feeds)
    }
    true
  end

  def disseminate_to_ciscp_feeds(xml_ciscp, oi_id, stix_id, date, ts,
                                 finished_feeds, disseminated_on,
                                 create_queue_records, failed_feeds)
    ciscp_feeds = @feeds.select { |key, feed|
      feed['profile'] == 'CISCP' && finished_feeds.exclude?(key)
    }
    ciscp_feeds.each { |key, feed|
      return false unless disseminate_to_feed(xml_ciscp, oi_id, stix_id,
                                              nil, date, ts, key, feed,
                                              finished_feeds, nil,
                                              disseminated_on,
                                              create_queue_records,
                                              failed_feeds)
    }
    true
  end

  def disseminate_sanitized_mappings(sanitized_mappings,*dissemination_labels)
    if @feeds['SANITIZED_MAPPINGS'].present?
      to_flare = []
      if (Setting.SEND_FLARE_IDS || 'PARENT').upcase=='PARENT'
        sanitized_mappings.uniq.each do |map|
          unless map.nil?
            a = {:original_id => map.before_id, :sanitized_id => map.after_id}
            to_flare << a
          end
        end
      else
        if dissemination_labels.present? && dissemination_labels[0].present? && dissemination_labels[0].key?('mapped_ids')
          to_flare={
                     "uploaded_file_id": dissemination_labels[0]['uploaded_file_id'].to_i,
                     "sanitized_package_id":
                     {
                       "original_id": "#{dissemination_labels[0]['original_stix_id']}",
                       "sanitized_id": "#{dissemination_labels[0]['stix_id']}"
                     },
                     "sanitized_object_ids": []
                   }
          mapped_ids=dissemination_labels[0]['mapped_ids']
          mapped_ids.delete(dissemination_labels[0]['original_stix_id'])
          mapped_ids.each do |before_id,after_id|
            to_flare[:sanitized_object_ids] << {"original_id": "#{before_id}", "sanitized_id": "#{after_id}"}
          end                  
        end
      end
      if to_flare.present?
        ts = Time.now.to_f.to_s.sub('.', '')
        write_file((@feeds['SANITIZED_MAPPINGS']['directory']||'')+'/output_'+ts+'.json', to_flare.to_json, @feeds['SANITIZED_MAPPINGS']['feed'])
      end
    end
  end

  def transform_to_isa(transformer, xml, consent, stix_id,
                       skip_ais_statistic=false)
    xml_isa = transformer.transform_stix_xml(xml, 'isa', consent, true)
    if transformer.errors.present?
      full_text = transformer.errors.join('\n')
      log_error("XSLT Transformation to ISA Profile Failed:\n#{full_text}")
      AisStatistic.log_dissemination_failure(stix_id, 'XSLT Transformation Failed', full_text) unless skip_ais_statistic
      xml_isa = nil
    elsif xml_isa.present?
      xml_isa = xml_isa.force_encoding('UTF-8')
    end
    xml_isa
  end

  def transform_to_ais(transformer, xml, consent, stix_id,
                       skip_ais_statistic=false)
    xml_ais = transformer.transform_stix_xml(xml, 'ais', consent, false)
    if transformer.errors.present?
      full_text = transformer.errors.join('\n')
      log_error("XSLT Transformation to AIS Profile Failed:\n#{full_text}")
      AisStatistic.log_dissemination_failure(stix_id, 'XSLT Transformation Failed', full_text) unless skip_ais_statistic
      xml_ais = nil
    elsif xml_ais.present?
      xml_ais = xml_ais.force_encoding('UTF-8')
    end
    xml_ais
  end

  def get_files_from_db
    if Logging::Disseminate.count > 0
      last_disseminated =
          Logging::Disseminate.order(xml_updated_at: :desc).first
      start = last_disseminated.xml_updated_at.strftime("%Y-%m-%d %H:%M:%S UTC")
      latest_date = DateTime.parse(start)
    else
      start = ''
      latest_date = DateTime.parse('1970-01-01 00:00:00')
    end

    if start.length > 0
      # Go to the next second, because for whatever reason, updated_at>? acts like updated_at>=?
      start = Time.parse(start) + 1.second
      files = UploadedFile.where("updated_at>?", start).where(status: ActionStatus::SUCCEEDED).reorder(updated_at: :asc)
    else
      files = UploadedFile.where(status: ActionStatus::SUCCEEDED).reorder(updated_at: :asc)
    end
    [files, latest_date]
  end

  def get_queued_files_from_db(filtered)
    # Get any queued records
    queued = Logging::DisseminationQueue.all
    queued.each do |q|
      oi = OriginalInput.find(q.original_input_id)
      # If this is an AIS XML Transfer from CIAP, disable CISCP detection
      # by passing nil instead of Setting.CISCP_ID_PATTERNS to the
      # extract_package_info method.
      ciscp_id_patterns = oi.input_category == 'Upload' &&
          oi.input_sub_category == OriginalInput::XML_AIS_XML_TRANSFER ?
          nil : Setting.CISCP_ID_PATTERNS
      package_info =
          Stix::Stix111::PackageInfo.extract_package_info(oi.raw_content,
                                                          ciscp_id_patterns)
      filtered << {id: q.original_input_id, xml: oi.raw_content,
                   updated: q.updated, finished_feeds: q.finished_feeds,
                   from_queue: true, package_info: package_info,
                   mapping: oi.ciap_id_mappings[0]}
    end
  end

  def update_dissemination_queue(create_queue_records, latest_date,
                                 updated_disseminated_records)
    if updated_disseminated_records
      create_queue_records.each do |q|
        if q[:updated] <= latest_date
          dq = Logging::DisseminationQueue.find_by_original_input_id(q[:original_input_id])
          if dq
            dq.finished_feeds = q[:finished_feeds]
            dq.save
          else
            Logging::DisseminationQueue.create(q)
          end
        end
      end
    end
  end

  def purge_human_review
    # Get rid of human review XML older than 14 days that may contain PII
    replace = OriginalInput.where('input_sub_category=?',
                                  OriginalInput::XML_HUMAN_REVIEW_TRANSFER).
        where('updated_at < ?', 14.days.ago)

    replace.each do |r|
      log_info("Updating OriginalInput record ##{r.id}")
      r.raw_content = 'PII'
      r.input_sub_category = OriginalInput::XML_PII_CLEARED
      r.save
    end
  end

  def log_file_dissemination(finished_feeds, date, latest_date, stix_id,
                             disseminated_on, id, from_queue,
                             updated_disseminated_records)
    if finished_feeds.present?
      if latest_date.present? && date > latest_date
        latest_date = date
      end
      updated_disseminated_records = true
      # Log the dissemination of this file
      d = Logging::Disseminate.new
      d.stix_id = stix_id
      d.xml_updated_at = date
      d.disseminated_at = Time.now
      d.disseminated_on = disseminated_on
      d.save
      # Remove from the queue, if this is a queued file
      if from_queue
        Logging::DisseminationQueue.find_by_original_input_id(id).delete
      end
    end
    [latest_date, updated_disseminated_records]
  end

  def disseminate_files
    files, latest_date = get_files_from_db

    filtered = []
    create_queue_records = []
    sanitized_mappings = []
    updated_disseminated_records = false

    files.each do |f|
      f.original_inputs.each do |oi|
        # If this is an AIS XML Transfer from CIAP, disable CISCP detection
        # by passing nil instead of Setting.CISCP_ID_PATTERNS to the
        # extract_package_info method.
        ciscp_id_patterns = oi.input_category == 'Upload' &&
            oi.input_sub_category == OriginalInput::XML_AIS_XML_TRANSFER ?
            nil : Setting.CISCP_ID_PATTERNS
        package_info =
            Stix::Stix111::PackageInfo.extract_package_info(oi.raw_content,
                                                            ciscp_id_patterns)

        if package_info.is_ciscp || (oi.input_category == 'Upload' &&
            [OriginalInput::XML_SANITIZED, OriginalInput::XML_UNICORN,
             OriginalInput::XML_AIS_XML_TRANSFER].include?(oi.input_sub_category))
          filtered << {id: oi.id, xml: oi.raw_content, updated: f.updated_at,
                       package_info: package_info,
                       mapping: oi.ciap_id_mappings[0]}
        end
      end
    end

    # Get any queued records
    get_queued_files_from_db(filtered)

    transformer = Stix::Xslt::Transformer.new

    if filtered.present?
      filtered.each do |record|
        id = record[:id]
        finished_feeds =
            record[:finished_feeds].to_s.split(',').collect(&:strip)
        failed_feeds = []
        xml = record[:xml]
        date = record[:updated]
        package_info = record[:package_info]
        mapping = record[:mapping]
        if @mode == 'SFTP' || @mode == 'BOTH'
          unless @sftp
            @sftp = connect_to_sftp
            unless @sftp
              log_error("Cannot connect to #{@config['FLARE_SERVER']}")
              return false
            end
          end
        end
        consent = package_info.consent
        stix_id = package_info.stix_id
        tlp_color = package_info.tlp_color.to_s.upcase
        is_federal = package_info.is_federal
        is_ciscp = package_info.is_ciscp

        if is_ciscp
          # CISCP files are not transformed by the XSLT transformer class.
          log_info("PackageInfo: STIX ID=#{stix_id}, CISCP")
          # Force the encoding to UTF-8 as is done for XML that is disseminated.
          xml_ciscp = xml.force_encoding('UTF-8')
          # All CISCP files are disseminated.
          disseminated_on=[]
          # ts = Time to microseconds, with the microsecond separator removed
          ts = Time.now.to_f.to_s.sub('.', '')
          disseminate_to_ciscp_feeds(xml_ciscp, id, stix_id, date, ts,
                                     finished_feeds, disseminated_on,
                                     create_queue_records, failed_feeds)
          latest_date, updated_disseminated_records =
              log_file_dissemination(finished_feeds, date, latest_date, stix_id,
                                     disseminated_on, id, record[:from_queue],
                                     updated_disseminated_records)
        elsif %w(WHITE GREEN AMBER).include?(tlp_color)
          # If this is not a CISCP file, the XML must be transformed to the
          # ISA and AIS profiles.
          if consent.nil?
            consent = 'NONE'
            log_warn('Consent not specified, setting to NONE')
          end
          log_info("PackageInfo: STIX ID=#{stix_id}, Consent=#{consent}, TLP=#{tlp_color}, " + (is_federal ? "Federal" : "Non-Federal"))
          xml_isa = transform_to_isa(transformer, xml, consent, stix_id, false)
          xml_ais = transform_to_ais(transformer, xml, consent, stix_id, false)
          # Files are only disseminated if they have a TLP color of WHITE, GREEN, or AMBER.
          disseminated_on=[]
          # ts = Time to microseconds, with the microsecond separator removed
          ts = Time.now.to_f.to_s.sub('.', '')
          disseminate_to_isa_feeds(xml_isa, id, stix_id, mapping, date, ts,
                                   finished_feeds, sanitized_mappings,
                                   disseminated_on, create_queue_records,
                                   failed_feeds)
          if tlp_color != 'AMBER' || (tlp_color == 'AMBER' && is_federal)
            disseminate_to_ais_feeds(xml_ais, id, stix_id, mapping, date,
                                     ts, finished_feeds, sanitized_mappings,
                                     disseminated_on, create_queue_records,
                                     failed_feeds)
          end
          latest_date, updated_disseminated_records =
              log_file_dissemination(finished_feeds, date, latest_date, stix_id,
                                     disseminated_on, id, record[:from_queue],
                                     updated_disseminated_records)
        else
          log_warn('Skipped, due to TLP_COLOR')
        end
      end

      disseminate_sanitized_mappings(sanitized_mappings)

      update_dissemination_queue(create_queue_records, latest_date,
                                 updated_disseminated_records)
    else
      log_info('No records found')
    end

    # Get rid of human review XML older than 14 days that may contain PII
    purge_human_review

    true
  end

  def disseminate_file(oi, dissemination_labels)
    id = oi.id
    xml = oi.raw_content
    date = oi.updated_at
    mapping = oi.ciap_id_mappings[0]
    consent = dissemination_labels['consent']
    stix_id = dissemination_labels['stix_id']
    tlp_color = dissemination_labels['tlp_color']
    is_federal = dissemination_labels['is_federal']
    is_ciscp = dissemination_labels['is_ciscp']
    create_queue_records = []
    sanitized_mappings = []
    finished_feeds = []
    failed_feeds = []
    updated_disseminated_records = false
    latest_date = DateTime.parse('1970-01-01 00:00:00')
    transformer = Stix::Xslt::Transformer.new

    if @mode == 'SFTP' || @mode == 'BOTH'
      unless @sftp
        @sftp = connect_to_sftp
        unless @sftp
          log_error("Cannot connect to #{@config['FLARE_SERVER']}")
          return false
        end
      end
    end

    if is_ciscp
      # CISCP files are not transformed by the XSLT transformer class.
      log_info("PackageInfo: STIX ID=#{stix_id}, CISCP")
      # Force the encoding to UTF-8 as is done for XML that is disseminated.
      xml_ciscp = xml.force_encoding('UTF-8')
      # All CISCP files are disseminated.
      disseminated_on=[]
      # ts = Time to microseconds, with the microsecond separator removed
      ts = Time.now.to_f.to_s.sub('.', '')
      disseminate_to_ciscp_feeds(xml_ciscp, id, stix_id, date, ts,
                                 finished_feeds, disseminated_on,
                                 create_queue_records, failed_feeds)
      latest_date,  updated_disseminated_records =
          log_file_dissemination(finished_feeds, date, latest_date, stix_id,
                                 disseminated_on, id, false,
                                 updated_disseminated_records)
    elsif %w(WHITE GREEN AMBER).include?(tlp_color)
      # If this is not a CISCP file, the XML must be transformed to the
      # ISA and AIS profiles.
      if consent.nil?
        consent = 'NONE'
        log_warn('Consent not specified, setting to NONE')
      end
      log_info("PackageInfo: STIX ID=#{stix_id}, Consent=#{consent}, TLP=#{tlp_color}, #{is_federal ? 'Federal' : 'Non-Federal'}")
      xml_isa = transform_to_isa(transformer, xml, consent, stix_id, false)
      xml_ais = transform_to_ais(transformer, xml, consent, stix_id, false)
      # Files are only disseminated if they have a TLP color of WHITE, GREEN, or AMBER.
      disseminated_on=[]
      # ts = Time to microseconds, with the microsecond separator removed
      ts = Time.now.to_f.to_s.sub('.', '')
      disseminate_to_isa_feeds(xml_isa, id, stix_id, mapping, date, ts,
                               finished_feeds, sanitized_mappings,
                               disseminated_on, create_queue_records,
                               failed_feeds)
      if tlp_color != 'AMBER' || (tlp_color == 'AMBER' && is_federal)
        disseminate_to_ais_feeds(xml_ais, id, stix_id, mapping, date,
                                 ts, finished_feeds, sanitized_mappings,
                                 disseminated_on, create_queue_records,
                                 failed_feeds)
      end
      latest_date, updated_disseminated_records =
          log_file_dissemination(finished_feeds, date, latest_date, stix_id,
                                 disseminated_on, id, false,
                                 updated_disseminated_records)
    else
      log_warn('Skipped, due to TLP_COLOR')
    end

    disseminate_sanitized_mappings(sanitized_mappings, dissemination_labels)

    update_dissemination_queue(create_queue_records, latest_date,
                               updated_disseminated_records)

    # Return the finished_feeds and failed_feeds arrays to the caller.
    [finished_feeds, failed_feeds]
  end

  def disseminate_xml_to_feed(xml_or_oi, feed, dissemination_labels)
    consent = dissemination_labels['consent']
    stix_id = dissemination_labels['stix_id']
    tlp_color = dissemination_labels['tlp_color']
    is_federal = dissemination_labels['is_federal']
    is_ciscp = dissemination_labels['is_ciscp']
    sanitized_mappings = []
    finished_feeds = []
    failed_feeds = []
    disseminated_on = []
    # ts = Time to microseconds, with the microsecond separator removed
    ts = Time.now.to_f.to_s.sub('.', '')

    if xml_or_oi.is_a?(OriginalInput)
      id = xml_or_oi.id
      date = xml_or_oi.updated_at
      mapping = xml_or_oi.ciap_id_mappings[0]
      xml = xml_or_oi.utf8_raw_content
    else
      id = stix_id
      date = Time.now
      mapping = nil
      xml = xml_or_oi
    end

    if @mode == 'SFTP' || @mode == 'BOTH'
      unless @sftp
        @sftp = connect_to_sftp
        unless @sftp
          log_error("Cannot connect to #{@config['FLARE_SERVER']}")
          failed_feeds << feed['feed_key']
          # Return the finished_feeds and failed_feeds arrays to the caller.
          return [finished_feeds, failed_feeds]
        end
      end
    end

    if is_ciscp
      log_info("PackageInfo: STIX ID=#{stix_id}, CISCP")
    else
      log_info("PackageInfo: STIX ID=#{stix_id}, Consent=#{consent}, TLP=#{tlp_color}, #{is_federal ? 'Federal' : 'Non-Federal'}")
    end

    if disseminate_to_feed(xml, id, stix_id, mapping, date, ts, nil, feed,
                           finished_feeds, sanitized_mappings, disseminated_on,
                           nil, failed_feeds)
      log_file_dissemination(finished_feeds, date, nil, stix_id,
                             disseminated_on, id, false, false)
    end

    disseminate_sanitized_mappings(sanitized_mappings, dissemination_labels)

    # Return the finished_feeds and failed_feeds arrays to the caller.
    [finished_feeds, failed_feeds]
  end

  def get_disseminations(xml, dissemination_labels)
    disseminations = []

    if dissemination_labels['is_ciscp']
      ciscp_feeds = @feeds.select { |key, feed| feed['profile'] == 'CISCP' }
      disseminations << {
          profile: 'CISCP',
          transfer_category: OriginalInput::XML_DISSEMINATION_CISCP_FILE,
          xml: xml,
          stix_id: dissemination_labels['stix_id'],
          feeds: ciscp_feeds
      } if ciscp_feeds.present?
    elsif dissemination_labels['tlp_color'].present? &&
        dissemination_labels['consent'].present?
      transformer = Stix::Xslt::Transformer.new
      isa_feeds = @feeds.select { |key, feed| feed['profile'] == 'ISA' }
      disseminations << {
          profile: 'ISA',
          transfer_category: OriginalInput::XML_DISSEMINATION_ISA_FILE,
          xml: transform_to_isa(transformer, xml,
                                dissemination_labels['consent'],
                                dissemination_labels['stix_id'], true),
          stix_id: dissemination_labels['stix_id'],
          feeds: isa_feeds
      } if isa_feeds.present?
      if dissemination_labels['tlp_color'] != 'AMBER' ||
          (dissemination_labels['tlp_color'] == 'AMBER' &&
              dissemination_labels['is_federal'] == true)
        ais_feeds = @feeds.select { |key, feed| feed['profile'] == 'AIS' }
        disseminations << {
            profile: 'AIS',
            transfer_category: OriginalInput::XML_DISSEMINATION_AIS_FILE,
            xml: transform_to_ais(transformer, xml,
                                  dissemination_labels['consent'],
                                  dissemination_labels['stix_id'], true),
            stix_id: dissemination_labels['stix_id'],
            feeds: ais_feeds
        } if ais_feeds.present?
      end
    end
    disseminations
  end

  def call_dq_processor(job, time)
    begin
      DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
      begin
        log_info("Dissemination queue processing job #{job.id} called at #{time}", @dq_logger_prefix)
        filtered = []
        create_queue_records = []
        sanitized_mappings = []
        updated_disseminated_records = false
        latest_date = DateTime.parse('1970-01-01 00:00:00')

        log_info('Loading queued dissemination records from the database...', @dq_logger_prefix)
        begin
          # Get any queued records
          get_queued_files_from_db(filtered)

          if filtered.present?
            log_info("#{filtered.size} records found")
            transformer = Stix::Xslt::Transformer.new

            log_info('Reattempting dissemination to remaining feeds for queued records...', @dq_logger_prefix)

            filtered.each do |record|
              id = record[:id]
              finished_feeds =
                  record[:finished_feeds].to_s.split(',').collect(&:strip)
              failed_feeds = []
              xml = record[:xml]
              date = record[:updated]
              package_info = record[:package_info]
              mapping = record[:mapping]
              if @mode == 'SFTP' || @mode == 'BOTH'
                unless @sftp
                  @sftp = connect_to_sftp
                  unless @sftp
                    log_error("Cannot connect to #{@config['FLARE_SERVER']}")
                    log_error("Dissemination queue processing job #{job.id} failed.", @dq_logger_prefix)
                    return
                  end
                end
              end
              consent = package_info.consent
              stix_id = package_info.stix_id
              tlp_color = package_info.tlp_color.to_s.upcase
              is_federal = package_info.is_federal
              is_ciscp = package_info.is_ciscp

              if is_ciscp
                # CISCP files are not transformed by the XSLT transformer class.
                log_info("PackageInfo: STIX ID=#{stix_id}, CISCP")
                # Force the encoding to UTF-8 as is done for XML that is disseminated.
                xml_ciscp = xml.force_encoding('UTF-8')
                # All CISCP files are disseminated.
                disseminated_on=[]
                # ts = Time to microseconds, with the microsecond separator removed
                ts = Time.now.to_f.to_s.sub('.', '')
                disseminate_to_ciscp_feeds(xml_ciscp, id, stix_id, date, ts,
                                           finished_feeds, disseminated_on,
                                           create_queue_records, failed_feeds)
                latest_date, updated_disseminated_records =
                    log_file_dissemination(finished_feeds, date, latest_date, stix_id,
                                           disseminated_on, id, record[:from_queue],
                                           updated_disseminated_records)
              elsif %w(WHITE GREEN AMBER).include?(tlp_color)
                # If this is not a CISCP file, the XML must be transformed to the
                # ISA and AIS profiles.
                if consent.nil?
                  consent = 'NONE'
                  log_warn('Consent not specified, setting to NONE')
                end
                log_info("PackageInfo: STIX ID=#{stix_id}, Consent=#{consent}, TLP=#{tlp_color}, " + (is_federal ? "Federal" : "Non-Federal"))
                xml_isa = transform_to_isa(transformer, xml, consent, stix_id, false)
                xml_ais = transform_to_ais(transformer, xml, consent, stix_id, false)
                # Files are only disseminated if they have a TLP color of WHITE, GREEN, or AMBER.
                disseminated_on=[]
                # ts = Time to microseconds, with the microsecond separator removed
                ts = Time.now.to_f.to_s.sub('.', '')
                disseminate_to_isa_feeds(xml_isa, id, stix_id, mapping, date, ts,
                                         finished_feeds, sanitized_mappings,
                                         disseminated_on, create_queue_records,
                                         failed_feeds)
                if tlp_color != 'AMBER' || (tlp_color == 'AMBER' && is_federal)
                  disseminate_to_ais_feeds(xml_ais, id, stix_id, mapping, date,
                                           ts, finished_feeds, sanitized_mappings,
                                           disseminated_on, create_queue_records,
                                           failed_feeds)
                end
                latest_date, updated_disseminated_records =
                    log_file_dissemination(finished_feeds, date, latest_date, stix_id,
                                           disseminated_on, id, record[:from_queue],
                                           updated_disseminated_records)
              else
                log_warn('Skipped, due to TLP_COLOR')
              end
            end

            disseminate_sanitized_mappings(sanitized_mappings)

            update_dissemination_queue(create_queue_records, latest_date,
                                       updated_disseminated_records)
          else
            log_info('No records found', @dq_logger_prefix)
          end
          log_info("Dissemination queue processing job #{job.id} successfully completed.", @dq_logger_prefix)
        rescue Exception => e
          log_error("Exception thrown while running dissemination queue processing job #{job.id}: #{e.message}", @dq_logger_prefix)
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
        @dq_running_job_mutex.synchronize {
          @dq_running_job_cv.signal
        }
      end
      DatabasePoolLogging.log_thread_exit(self.class.to_s, __LINE__)
    end
  end

  def start_dq_processor
    if @dq_scheduler.present?
      Thread.new do
        begin
          DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
          processor = DisseminationQueueProcessor.new(self)
          # Schedule the first run immediately (i.e., in one second).
          @dq_scheduler.in('1s', processor)
          until @dq_shutdown_requested
            @dq_running_job_mutex.synchronize {
              @dq_running_job_cv.wait(@dq_running_job_mutex)
            }
            unless @dq_shutdown_requested
              processor = DisseminationQueueProcessor.new(self)
              @dq_scheduler.in(@wait_between_runs, processor)
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
        end
        DatabasePoolLogging.log_thread_exit(self.class.to_s, __LINE__)
      end
    end
  end

  # This is a Rufus Scheduler handler class used to simplify creating jobs.
  # Rufus will call the "call" method when it is ready to start the job.
  class DisseminationQueueProcessor
    def initialize(dissemination_service)
      @dissemination_service = dissemination_service
    end

    # Rufus will call this method to start the job.
    def call(job, time)
      # Hand things off to the "call_processor" method on the processing
      # service to do the real work.
      @dissemination_service.call_dq_processor(job, time)
    end
  end
end
