class AisStatistic < ActiveRecord::Base

  self.table_name = 'ais_statistics'

  belongs_to :stix_package, class_name: 'StixPackage', primary_key: :stix_id, foreign_key: :stix_package_stix_id
  before_save :trickledown_feed
  
  has_many :system_logs, class_name: 'Logging::SystemLog', primary_key: :stix_package_stix_id, foreign_key: :sanitized_package_id

  # Even though we can go to stix package from uploaded file we need this association for human review since it hasnt uploaded the stix package when we are doing human review it just has original inputs
  belongs_to :uploaded_file, class_name: 'UploadedFile', primary_key: :id, foreign_key: :uploaded_file_id
  has_one :human_review, through: :uploaded_file

  include Auditable
  include Guidable
  include Serialized
  
  # Adds the disseminated feeds to the package object.
  def trickledown_feed   
      begin  
        if self.feeds.present? && self.stix_package.present?
          self.stix_package.update_attribute(:feeds, self.feeds)        
        end
      rescue Exception => e
        ex_msg = "Exception during trickledown_feed on: " + self.class.name    
        ExceptionLogger.debug("#{ex_msg}" + ". #{e.to_s}")
      end
  end    

  def self.custom_save_or_update(attributes)
    AisStatisticLogger.debug("[AisStatistic][custom_save_or_update]: saving attributes: #{attributes}")
    ais_stats = attributes.try(:deep_stringify_keys)
    ais_statistics = []
    system_logs = []
    if ais_stats.present?
      ais_stats["ais_statistic"].each { |ais_stat|
        #id_attrs = ais_stat.slice(:guid, :ais_uid, :stix_package_stix_id,
        #                            :stix_package_original_id).compact
        system_log_attrs = ais_stat["system_logs"] || []

        if AppUtilities.is_ciap?
          ais_statistic = AisStatistic.where("stix_package_original_id" => ais_stat["stix_package_original_id"]).first || AisStatistic.where("stix_package_stix_id" => ais_stat["stix_package_stix_id"]).first || AisStatistic.new
        else
          ais_statistic = AisStatistic.new
        end

        # This should be populated from flare
        if ais_statistic["received_time"].blank? && ais_stat["received_time"].blank? && !Ingest.is_ais_provider_user?(User.current_user) && ais_stat["ecis_status"].blank?
          ais_statistic.received_time = Time.now
        end

        # If the original ID is blank try to find it in the mappings table.
        if AppUtilities.is_ciap? && (ais_statistic["stix_package_stix_id"].present? || ais_stat["stix_package_stix_id"].present?)
          mapped_id = CiapIdMapping.find_by_after_id(ais_statistic["stix_package_stix_id"].to_s) || CiapIdMapping.find_by_after_id(ais_stat["stix_package_stix_id"].to_s)
          if mapped_id.present?
            mapped_id = mapped_id.before_id
          end
          ais_statistic["stix_package_original_id"] = mapped_id || ais_statistic["stix_package_stix_id"] || ais_stat["stix_package_stix_id"]
        end

        if AppUtilities.is_ciap? && ais_stat["ecis_status"].present? &&
            ais_stat["ecis_status"] == true &&
            ais_stat["ecis_status_hr"].blank? &&
            ais_statistic.ecis_status.present? &&
            ais_statistic.ecis_status == true &&
            ais_statistic.ecis_status_hr.blank?
          # This setting of the _hr attribute if the non-hr attribute is already
          # set to true in the database also occurs for :ecis_status.
          ais_statistic.ecis_status_hr = ais_stat.delete("ecis_status").try(:to_bool)
        end

        if AppUtilities.is_ciap? && ais_stat["flare_out_status"].present? &&
            ais_stat["flare_out_status"] == true &&
            ais_stat["flare_out_status_hr"].blank? &&
            ais_statistic.flare_out_status.present? &&
            ais_statistic.flare_out_status == true &&
            ais_statistic.flare_out_status_hr.blank? && 
            ais_statistic.ecis_status_hr == true
          # This setting of the _hr attribute if the non-hr attribute is already
          # set to true in the database also occurs for :flare_out_status.
          ais_statistic.flare_out_status_hr = ais_stat.delete("flare_out_status").try(:to_bool)
        end
        
        if AppUtilities.is_ciap? && 
            (ais_stat["dissemination_time"].present? || ais_statistic.dissemination_time.present?) &&
            ais_statistic.dissemination_time_hr.blank? && 
            ais_statistic.flare_out_status_hr == true
          # If an empty string is explicitly passed as the value of the
          # :dissemination_time_hr attribute, the value passed for the
          # :dissemination_time attribute will be stored instead as the
          # :dissemination_time_hr attribute if the :dissemination_time is
          # already set in the the database record.
          ais_statistic.dissemination_time_hr = ais_stat.delete("dissemination_time").try(:to_datetime)
        end

        if ais_stat["feeds"].present? || ais_statistic.feeds.present?
          attr_feeds = ais_stat["feeds"].to_s.split(',')
          old_feeds = ais_statistic.feeds.to_s.split(',')
          new_feeds = old_feeds | attr_feeds
          ais_statistic.feeds = new_feeds.present? ? new_feeds.join(',') : nil
        end

        # If messages were recieved we will parse them into system logs
        if ais_stat["message"].present?
          ais_stat["message"].each do |x|
            # Build a system log for each message
            s = Logging::SystemLog.new
            s.stix_package_id = ais_statistic.stix_package_stix_id
            s.sanitized_package_id = ais_statistic.stix_package_original_id
            s.timestamp = ais_stat["received_time"] || Time.now
            s.source = ais_stat["component"]
            s.log_level = ais_stat["status"] ? "200" : "400"
            s.message = x

            begin
              s.save!
            rescue Exception => e
              AisStatisticLogger.error("[ais_statistics][SystemLog] SystemLog (#{x}) failed to save, exception: #{e.message}")
            end

            # Add the record to the system logs array
            if s.errors.blank?
              system_logs << s
            end
          end
        end

        ais_statistic.attributes = ais_statistic.attributes.merge(ais_stat.except("system_logs", "feeds").compact)

        # If this is a new record and the received time is still blank after mergining, set it now.
        if ais_statistic.id.blank? && ais_statistic.received_time.blank?
          ais_statistic.received_time = Time.now
        end

        system_log_attrs.reject(&:blank?).each { |sl|
          sl_attrs = sl.compact
          next if sl_attrs.blank?
          system_log = Logging::SystemLog.new
          system_log.stix_package_id = sl_attrs["stix_package_id"]
          system_log.log_level = sl_attrs["log_level"]
          system_log.timestamp = sl_attrs["timestamp"]
          system_log.source = sl_attrs["source"]
          system_log.message = sl_attrs["message"]
          begin
            system_log.save!
          rescue Exception => e
            AisStatisticLogger.error("[ais_statistics][SystemLog] SystemLog (#{system_log}) failed to save, exception: #{e.message}")
          end
          system_logs << system_log
        }
        begin
          ais_statistic.save!
        rescue Exception => e
          AisStatisticLogger.error("[ais_statistics][ais_statistic] Ais Statistic (#{ais_statistic}) failed to save, exception: #{e.message}")
        end
        ais_statistics << ais_statistic
      }
    end
    AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Done Saving, ais_statistics: #{ais_statistics}, system_logs: #{system_logs}")
    [ais_statistics, system_logs]
  end

  def self.log_dissemination_success(stix_id, feed_name, message, text=nil)
    dissemination_time = DateTime.now

    ais_statistic_attrs = {
        "ais_statistic": [
            {
                "stix_package_stix_id": stix_id,
                #"dissemination_time": dissemination_time,
                #"dissemination_time_hr": '',
                #"feeds": feed_name,
                "system_logs": [
                    {
                        "stix_package_id": stix_id,
                        "timestamp": dissemination_time,
                        "source": 'DISENG',
                        "log_level": 'INFO',
                        "message": message,
                        "text": text
                    }
                ]
            }
        ]
    }

    self.custom_save_or_update(ais_statistic_attrs)
  end

  def self.log_dissemination_failure(stix_id, message, text=nil)
    dissemination_time = DateTime.now

    ais_statistic_attrs = {
        "ais_statistic": [
            {
                "stix_package_stix_id": stix_id,
                "system_logs": [
                    {
                        "stix_package_id": stix_id,
                        "timestamp": dissemination_time,
                        "source": 'DISENG',
                        "log_level": 'ERROR',
                        "message": message,
                        "text": text
                    }
                ]
            }
        ]
    }

    self.custom_save_or_update(ais_statistic_attrs)
  end

  def self.log_uploaded_file_result(uploaded_file)
    return [] unless uploaded_file.present?

    source = AppUtilities.is_ciap? ? 'CIAP' : 'ECIS'
    ais_statistics = []

    AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Capturing Stix ID to save into statistic")
    stix_id = nil
    uploaded_file_oi = uploaded_file.original_inputs.source
    if uploaded_file_oi.present?
      ids = /id=["'](.+?)["']/.match(uploaded_file_oi.raw_content)
      if ids.present?
        stix_id = ids.captures.first
      end
    end

    sanitized_stix_id = nil
    sanitized_upload = uploaded_file.original_inputs.where(:input_sub_category => "Sanitized").first
    if sanitized_upload.present?
      ids = /id=["'](.+?)["']/.match(sanitized_upload.raw_content)
      if ids.present?
        sanitized_stix_id = ids.captures.first
      end
    end

    AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Uploaded file Status is: #{uploaded_file.status}")
    # Whenever it reaches ECIS it should be the sanitized id.
    if AppUtilities.is_ecis? && stix_id.present? && sanitized_stix_id.nil?
      sanitized_stix_id = stix_id
      stix_id = nil
    end

    if uploaded_file.status == 'S'
      AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Status is S")
      if uploaded_file.stix_packages.present?
        AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Package is present")
        uploaded_file.stix_packages.each { |stix_package|
          ais_statistics << {
              "stix_package_original_id": stix_id,
              "stix_package_stix_id": stix_package.stix_id,
              "ciap_status": source == 'CIAP' ? true : nil,
              "ecis_status": source == 'ECIS' ? true : nil,
              "indicator_amount": stix_package.indicators.present? ? stix_package.indicators.count : 0,
              "uploaded_file_id": uploaded_file.id.to_s,
              "system_logs": [
                  {
                      "stix_package_id": stix_package.stix_id,
                      "timestamp": uploaded_file.updated_at,
                      "source": source,
                      "log_level": 'INFO',
                      "message": "Successfully uploaded stix_package_stix_id: #{stix_package.stix_id} as uploaded_file: #{uploaded_file.id}"
                  }
              ]
          }
        }
      else
        if uploaded_file.human_review.present?
          message = "Successfully placed file for human review: #{stix_id}, as uploaded_file: #{uploaded_file.id}"
        else
          message = "Successfully recieved Package: #{stix_id}, as uploaded_file: #{uploaded_file.id}"
        end

        if stix_id.present? || sanitized_stix_id.present?
          AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Stix ID Found: #{stix_id}, Saving AIS Statistic Information")
          ais_statistics << {
              "stix_package_original_id": stix_id,
              "stix_package_stix_id": sanitized_stix_id,
              "ciap_status": source == 'CIAP' ? true : nil,
              "ecis_status": source == 'ECIS' ? true : nil,
              "uploaded_file_id": uploaded_file.id.to_s,
              "system_logs": [
                  {
                      "stix_package_id": stix_id,
                      "timestamp": uploaded_file.updated_at,
                      "source": source,
                      "log_level": 'INFO',
                      "message": message
                  }
              ]
          }
        else
          AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Couldn't find Stix ID for package. No Stats record created.")
        end
      end
    elsif uploaded_file.status == 'F'
      AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Status is F")
      if uploaded_file.stix_packages.present?
        AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Package is present")
        uploaded_file.stix_packages.each { |stix_package|
          ais_statistics << {
              "stix_package_original_id": stix_id,
              "stix_package_stix_id": stix_package.stix_id,
              "ciap_status": source == 'CIAP' ? false : nil,
              "ecis_status": source == 'ECIS' ? false : nil,
              "indicator_amount": stix_package.indicators.present? ? stix_package.indicators.count : 0,
              "uploaded_file_id": uploaded_file.id.to_s,
              "system_logs": [
                  {
                      "stix_package_id": stix_package.stix_id,
                      "timestamp": uploaded_file.updated_at,
                      "source": source,
                      "log_level": 'ERROR',
                      "message": "Failed to upload stix_package_stix_id: #{stix_package.stix_id} as uploaded_file: #{uploaded_file.id}",
                      "text": uploaded_file.error_messages.to_s
                  }
              ]
          }
        }
      else
        if stix_id.present? || sanitized_stix_id.present?
          AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Stix ID Found: #{stix_id}, Saving AIS Statistic Information")
          ais_statistics << {
              "stix_package_original_id": stix_id,
              "stix_package_stix_id": sanitized_stix_id,
              "ciap_status": source == 'CIAP' ? false : nil,
              "ecis_status": source == 'ECIS' ? false : nil,
              "uploaded_file_id": uploaded_file.id.to_s,
              "system_logs": [
                  {
                      "stix_package_id": stix_id,
                      "timestamp": uploaded_file.updated_at,
                      "source": source,
                      "log_level": 'INFO',
                      "message": "Failed to upload package with id: #{stix_id}, as uploaded_file: #{uploaded_file.id}"
                  }
              ]
          }
        else
          AisStatisticLogger.debug("[AisStatistic][log_uploaded_file_result]: Couldn't find Stix ID for package. No Stats record created.")
        end
      end
    end

    if ais_statistics.present?
      ais_statistic_attrs = {
          "ais_statistic": ais_statistics
      }
      self.custom_save_or_update(ais_statistic_attrs)
    else
      []
    end
  end

  # {
  #   (stix_package_original_id/stix_package_stix_id): string,
  #   component: (flare_in/flare_out),
  #   status: (true/false),
  #   received_time: string,
  #   feed: string,
  #   message: [
  #     string, 
  #     string, 
  #     string...
  #   ]
  # }
  # To use the existing code that is wrote we will parse this string into
  # Something that is recognizable by what was written
  # {
  #   :id => nil,
  #   :stix_package_stix_id => nil,
  #   :stix_package_original_id => nil,
  #   :uploaded_file_id => nil,
  #   :feeds => nil,
  #   :messages => nil,
  #   :ais_uid => nil,
  #   :guid => nil,
  #   :indicator_amount => nil,
  #   :flare_in_status => nil,
  #   :ciap_status => nil,
  #   :ecis_status => nil,
  #   :flare_out_status => nil,
  #   :ecis_status_hr => nil,
  #   :flare_out_status_hr => nil,
  #   :dissemination_time => nil,
  #   :dissemination_time_hr => nil,
  #   :received_time => nil,
  #   :created_at => nil,
  #   :updated_at => nil
  # }
  def self.parse_and_store_amqp_ais_statistics_flare(repl_type, flare_json)
    AisStatisticLogger.debug("[AisStatistic][parse_and_store_amqp_ais_statistics_flare]: Saving flare_json: #{flare_json}")
    ais_stat = ActiveSupport::JSON.decode(flare_json)
    if ais_stat.present?
      ais_json = {}
      if repl_type == Setting.FLARE_IN_REPL_TYPE
        ais_json["stix_package_original_id"] = ais_stat["stix_package_id"]
        ais_json["flare_in_status"] = ais_stat["status"]
        ais_json["received_time"] = ais_stat["received_time"]
      elsif repl_type == Setting.FLARE_OUT_REPL_TYPE
        ais_json["stix_package_stix_id"] = ais_stat["stix_package_id"]
        ais_json["flare_out_status"] = ais_stat["status"]
        ais_json["dissemination_time"] = ais_stat["received_time"]
      end

      ais_json["messages"] = ais_stat["message"]
      ais_json["feeds"] = ais_stat["feed"]

      AisStatisticLogger.debug("[AisStatistic][parse_and_store_amqp_ais_statistics_flare]: created: #{ais_json} from flare json.  Saving to Ais Statistic")
      ais_statistics, system_logs = self.custom_save_or_update({"ais_statistic" => [ais_json]})
    else
      ais_statistics = []
      system_logs = []
    end

    [ais_statistics, system_logs]
  end

  def self.store_amqp_replicated_ais_statistics(ais_statistics_json)
    ais_stats = ActiveSupport::JSON.decode(ais_statistics_json)
    if ais_stats.present?
      ais_statistics, system_logs = self.custom_save_or_update({"ais_statistic" => ais_stats})
    else
      ais_statistics = []
      system_logs = []
    end
    [ais_statistics, system_logs]
  end

  def self.validate_ais_statistics(ais_statistics, force_reload=true)
    ais_stats_with_errors = []
    if ais_statistics.present?
      ais_statistics.each { |ais_statistic|
        begin
          if ais_statistic.valid?
            ais_statistic.reload if force_reload
          else
            ais_stats_with_errors << {obj: ais_statistic,
                                      errors: ais_statistic.errors}
          end
        rescue Exception => e
          ais_stats_with_errors << {obj: ais_statistic,
                                    errors: e.message.to_s}
        end
      }
    end
    ais_stats_with_errors
  end

private

  searchable :auto_index => (Setting.SOLR_INDEX_FREQUENCY_IN_SECONDS||0)==0 do
    string :stix_package_stix_id
    string :stix_package_original_id
    string :uploaded_file_id
    string :feeds
    string :messages
    string :ais_uid

    text :stix_package_stix_id, as: :text_exactm
    text :stix_package_original_id, as: :text_exactm
    text :uploaded_file_id, as: :text_exactm
    text :ais_uid
    text :feeds
    text :messages
    text :guid, as: :text_exact

    text :human_review_status do
      human_review.present? ? human_review.status : nil
    end

    time :dissemination_time
    time :dissemination_time_hr
    time :received_time

    integer :indicator_amount

    boolean :flare_in_status
    boolean :ciap_status
    boolean :ecis_status
    boolean :flare_out_status
    boolean :ecis_status_hr
    boolean :flare_out_status_hr

    #Configure for Sunspot, but don't build indices for searching.  Needed for sorting while searching
    time :created_at, stored: false
    time :updated_at, stored: false
  end

end
