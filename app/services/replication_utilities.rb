class ReplicationUtilities
  class << self

    def replicate_ais_statistics(ais_statistics, repl_type)
      ReplicationLogger.debug("[ReplicationUtilities][Replicate_ais_statistics]: ais_statistics: #{ais_statistics}, repl_type is #{repl_type}")
      if ais_statistics.present?
        begin
          ais_statistics_json = ais_statistics.to_json
          guids = ais_statistics.collect(&:guid).compact

          if ais_statistics_json.present?
            replications = Replication.where(repl_type: repl_type)
            if replications.present?
              replications.each { |replication|
                ais_statistics.each { |ais_statistic|
                  ReplicationLogger.debug("[ais_statistics][replicate?]: stix_package_stix_id: #{ais_statistic.stix_package_stix_id}, stix_package_original_id: #{ais_statistic.stix_package_original_id}, guid: #{ais_statistic.guid}, ais_uid: #{ais_statistic.ais_uid}")
                }
                if replication.api_key.present?
                  ReplicationLogger.debug("[ais_statistics][ais_statistic(s) to replicate] ais_statistic(s): #{guids} content: \n#{ais_statistics_json}")
                  Thread.new do
                    begin
                      DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
                      replication.send_data(ais_statistics_json, {'Content-type' => 'application/json'})
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
                else
                  ReplicationLogger.debug("[ais_statistics][replicate_user_check?]: Replication was not setup correctly. This record could not replicate to #{replication.url}")
                end
              }
            else
              ReplicationLogger.debug("[ReplicationUtilities][Replicate_ais_statistics]: Replications are not setup")
            end
          end
        rescue Exception => e
          ReplicationLogger.error("[ais_statistics][ais_statistic(s) failed to replicate] ais_statistic(s): #{guids}, exception: #{e.message}")
          ReplicationLogger.debug("[ais_statistics][ais_statistic(s) failed to replicate] ais_statistic(s): #{guids}, backtrace: #{e.backtrace}")
        end
      end
    end

    def replicate_xml(xml, id, repl_type, replicating_user=nil,
                      transfer_category=nil, final=false, dissemination_labels={})
      replications = Replication.where(repl_type: repl_type)
      return true unless replications.present?
      replications.each do |replication|
        if replicating_user.nil? || replicating_user.api_key == replication.api_key
          Thread.new do
            begin
              DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
              if transfer_category == OriginalInput::XML_DISSEMINATION_TRANSFER
                log_msg =
                    "[replication_utilities][replicate_xml][dissemination transfer] original input id: #{id} dissemination_labels: #{dissemination_labels.to_s} content: \n#{xml}"
                props_hash = {
                    'transfer_category' => OriginalInput::XML_DISSEMINATION_TRANSFER,
                    'dissemination_labels' => dissemination_labels.to_json,
                    'final' => final.to_s

                }
              elsif transfer_category == OriginalInput::XML_AIS_XML_TRANSFER
                log_msg = "[replication_utilities][replicate_xml][ais xml transfer] package id: #{id} content: \n#{xml}"
                props_hash = {
                    'transfer_category' => OriginalInput::XML_AIS_XML_TRANSFER,
                    'final' => final.to_s
                }
              else
                log_msg = "[replication_utilities][replicate_xml][file to replicate] original input id: #{id} content: \n#{xml}"
                props_hash = {'Content-type' => 'application/xhtml+xml'}
              end
              ReplicationLogger.debug(log_msg)
              replication.send_data(xml, props_hash)
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
        else
          ReplicationLogger.debug("[replication_utilities][replicate_xml][replicate_user_check?]: #{replicating_user.username} does not have permission to replicate to #{replication.url}")
        end
      end
    end

    def disseminate_xml(xml, id, repl_type, dissemination_labels, final=false)
      Thread.new do
        begin
          DatabasePoolLogging.log_thread_entry(self.class.to_s, __LINE__)
          replications = Replication.where(repl_type: repl_type)
          if replications.present?
            dissemination_labels_json = dissemination_labels.to_json
            replications.each { |replication|
              disseminator = DisseminationService.new
              disseminations =
                  disseminator.get_disseminations(xml, dissemination_labels)
              disseminations.each { |dissemination|
                next unless dissemination[:xml].present? &&
                    dissemination[:feeds].present?
                log_msg =
                    "[replication_utilities][disseminate_xml][dissemination transfer] original input id: #{id} feeds: #{dissemination[:feeds].keys.join(', ')} dissemination_labels: #{dissemination_labels.to_s} content:\n#{xml}"
                ReplicationLogger.debug(log_msg)
                dissemination[:feeds].each { |key, feed|
                  feed['feed_key'] = key
                  props_hash = {
                      'transfer_category' =>
                          dissemination[:transfer_category],
                      'dissemination_feed' => feed.to_json,
                      'dissemination_labels' => dissemination_labels_json
                  }
                  log_msg =
                      "[replication_utilities][disseminate_xml][dissemination transfer] original input id: #{id} feed: #{feed['feed_key']}"
                  ReplicationLogger.debug(log_msg)
                  replication.send_data(dissemination[:xml], props_hash)
                }
              }
            }
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

    def log_non_replication(reason, id, class_name, line_num)
      return if Setting.LOG_NON_REPLICATION_ENABLED == false
      message_text = '[replication_utilities][log_non_replication] ' +
          "original input id: #{id} will not be replicated.\n" +
          "Reason: #{reason}\n" +
          "Line #{line_num} of #{class_name}"
      ReplicationLogger.debug("#{ message_text }")
    end
  end
end
