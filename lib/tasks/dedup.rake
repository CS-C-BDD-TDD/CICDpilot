namespace :dedup do
  task :start => :environment do |t, args|

    fields = {}

    # The following fields are not checked for Address:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    fields["Address"] = [ :address_value_raw, :address_value_normalized,
                          :category, :cybox_hash, :ip_value_calculated_start,
                          :ip_value_calculated_end, :iso_country_code,
                          :com_threat_score, :gov_threat_score,
                          :agencies_sensors_seen_on, :first_date_seen_raw,
                          :first_date_seen, :last_date_seen_raw,
                          :last_date_seen, :combined_score, :category_list ]

    # The following fields are not checked for CyboxMutex:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    fields["CyboxMutex"] = [ :cybox_hash, :name, :name_condition ]

    # The following fields are not checked for Domain:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    fields["Domain"] = [ :cybox_hash, :name_raw, :name_condition, :Equals,
                         :name_normalized, :name_type, :root_domain ]

    # The following fields are not checked for DnsRecord:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    fields["DnsRecord"] = [ :address_class, :address_value_normalized,
                            :address_value_raw, :cybox_hash, :description,
                            :domain_normalized, :domain_raw, :entry_type,
                            :queried_date, :legacy_record_name,
                            :legacy_record_type, :legacy_ttl, :legacy_flags,
                            :legacy_data_length, :legacy_record_data ]

    # The following fields are not checked for EmailMessage:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   from_cybox_object_id - May be auto-generated
    #   reply_to_cybox_object_id - May be auto-generated
    #   sender_cybox_object_id - May be auto-generated
    #   cybox_object_id - Already know this is the same
    fields["EmailMessage"] = [ :cybox_hash, :email_date, :from_is_spoofed,
                               :from_raw, :from_normalized, :message_id,
                               :raw_body, :raw_header, :reply_to_raw,
                               :reply_to_normalized, :sender_is_spoofed,
                               :sender_raw, :sender_normalized, :subject,
                               :x_mailer, :x_originating_ip ]

    # The following fields are not checked for HttpSession:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    fields["HttpSession"] = [ :cybox_hash, :user_agent, :domain_name, :port,
                              :referer, :pragma ]

    # The following fields are not checked for NetworkConnection:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    fields["NetworkConnection"] = [ :cybox_hash, :dest_socket_address,
                                    :dest_socket_is_spoofed, :dest_socket_port,
                                    :old_dest_socket_protocol,
                                    :source_socket_address,
                                    :source_socket_is_spoofed,
                                    :source_socket_port,
                                    :old_source_socket_protocol,
                                    :dest_socket_hostname,
                                    :source_socket_hostname, :layer3_protocol,
                                    :layer4_protocol, :layer7_protocol ]

    # The following fields are not checked for Uri:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    fields["Uri"] = [ :cybox_hash, :label, :uri_normalized, :uri_raw,
                      :uri_type ]

    sep_fields = {}

    # The following fields are not checked for CyboxFile:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - Already know this is the same
    sep_fields["CyboxFile"] = [ :cybox_hash, :file_extension, :file_name,
                                :file_name_condition, :file_path,
                                :file_path_condition, :size_in_bytes,
                                :size_in_bytes_condition, :legacy_file_type,
                                :legacy_registry_edits,
                                :legacy_av_signature_mcafee,
                                :legacy_av_signature_microsoft,
                                :legacy_av_signature_symantec,
                                :legacy_av_signature_trendmicro,
                                :legacy_av_signature_kaspersky,
                                :legacy_compiled_at, :legacy_compiler_type,
                                :legacy_cve, :legacy_keywords, :legacy_mutex,
                                :legacy_packer, :legacy_xor_key,
                                :legacy_motif_name, :legacy_motif_size,
                                :legacy_composite_hash, :legacy_command_line ]

    # The following fields are not checked for FileHash:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - May be auto-generated
    #   cybox_file_id - Already know this is the same
    sep_fields["FileHash"] = [ :cybox_hash, :fuzzy_hash_value,
                               :fuzzy_hash_value_normalized, :hash_condition,
                               :hash_type, :hash_type_vocab_name,
                               :hash_type_vocab_ref, :simple_hash_value,
                               :simple_hash_value_normalized ]

    # The following fields are not checked for Registry:
    #   id - Different for every record
    #   created_at - Different for every record
    #   updated_at - Different for every record
    #   guid - Different for every record
    #   cybox_object_id - May be auto-generated
    sep_fields["Registry"] = [ :cybox_hash, :hive, :key ]

    # The following fields are not checked for FileHash:
    #   id - Different for every record
    #   guid - Different for every record
    #   cybox_win_reg_key_id - Already know this is the same
    sep_fields["RegistryValue"] = [ :reg_name, :reg_value, :cybox_hash ]

    def check_values(fields,one,two)
      result=true
      @different=[]
      fields.each do |f|
        unless one[f]==two[f]
          result=false
          @different << f
        end
      end
      result
    end

    fields.keys.each do |obj|
      ids=obj.constantize.pluck(:cybox_object_id).uniq
      ids.each do |i|
        records=obj.constantize.where("cybox_object_id=?",i)
        count=records.count
        if count>1
          (1..count-1).each do |x|
            if check_values(fields[obj],records[0],records[x])
              Sunspot.remove_by_id!(obj.constantize,records[x].id)
              records[x].delete
            else
              puts "Cannot delete #{obj} record with id #{records[x].id}.  " +
                   "The following fields are different:"
              @different.each do |f|
                puts "  #{f}"
              end
            end
          end
        end
      end
    end

    ids=CyboxFile.pluck(:cybox_object_id).uniq
    ids.each do |i|
      records=CyboxFile.where("cybox_object_id=?",i)
      count=records.count
      if count>1
        all_match=true
        file_recs_to_delete = []
        hash_recs_to_delete = []
        (1..count-1).each do |x|
          if check_values(sep_fields["CyboxFile"],records[0],records[x])
            file_recs_to_delete << records[x].id
          else
            puts "Cannot delete CyboxFile record with id #{records[x].id}.  " +
                 "The following fields are different:"
            @different.each do |f|
              puts "  #{f}"
            end
            all_match=false
          end
        end
        ['MD5','SHA1','SHA256','SSDEEP'].each do |hash|
          if all_match
            records=FileHash.where("cybox_file_id=?",i).where("hash_type=?",hash)
            count2=records.count
            if count2==count
              (1..count-1).each do |x|
                if check_values(sep_fields["FileHash"],records[0],records[x])
                  hash_recs_to_delete << records[x].id
                else
                  puts "Cannot delete FileHash record with id #{records[x].id}.  " +
                       "The following fields are different:"
                  @different.each do |f|
                    puts "  #{f}"
                  end
                  all_match=false
                end
              end
            else
              unless count2==0
                puts "Wrong number of #{hash} records for CyboxFile #{i}"
                all_match=false
              end
            end
          end
        end
        if all_match
          hash_recs_to_delete.each do |id|
            Sunspot.remove_by_id!(:FileHash,id)
            FileHash.find(id).delete
          end
          file_recs_to_delete.each do |id|
            Sunspot.remove_by_id!(:CyboxFile,id)
            CyboxFile.find(id).delete
          end
        end
      end
    end

    ids=Registry.pluck(:cybox_object_id).uniq
    ids.each do |i|
      records=Registry.where("cybox_object_id=?",i)
      count=records.count
      if count>1
        all_match=true
        registry_recs_to_delete = []
        value_recs_to_delete = []
        (1..count-1).each do |x|
          if check_values(sep_fields["Registry"],records[0],records[x])
            registry_recs_to_delete << records[x].id
          else
            puts "Cannot delete Registry record with id #{records[x].id}.  " +
                 "The following fields are different:"
            @different.each do |f|
              puts "  #{f}"
            end
            all_match=false
          end
        end
        if all_match
          records=RegistryValue.where("cybox_win_reg_key_id=?",i)
          ids={}
          records.each do |r|
            add_value="#{r.reg_name}\t#{r.reg_value}\t#{r.cybox_hash}"
            if ids[add_value]
              ids[add_value] << r.id
            else
              ids[add_value]=[r.id]
            end
          end
          ids.keys.each do |i|
            if ids[i].count==count
              ids[i].shift
              value_recs_to_delete+=ids[i]
            else
              puts "Count mismatch on registry value records #{ids[i]}"
              all_match=false
            end
          end
        end
        if all_match
          registry_recs_to_delete.each do |id|
            Sunspot.remove_by_id!(:Registry,id)
            Registry.find(id).delete
          end
          value_recs_to_delete.each do |id|
            Sunspot.remove_by_id!(:RegistryValue,id)
            RegistryValue.find(id).delete
          end
        end
      end
    end
  end

  task :observables => :environment do |t, args|
    ids=Observable.pluck(:stix_indicator_id).uniq
    ids.each do |i|
      counts={}
      observables=Observable.where("stix_indicator_id=?",i)
      if observables.count>1
        observables.each do |o|
          (counts[o.remote_object_type] ||= {})[o.remote_object_id] ||= 0
          (counts[o.remote_object_type] ||= {})[o.remote_object_id] += 1
        end
        counts.keys.each do |type|
          counts[type].keys.each do |id|
            if counts[type][id]>1
              remove=Observable.where("stix_indicator_id=?",i).where("remote_object_type=?",type).where("remote_object_id=?",id).pluck(:id)
              remove.shift
              remove.each do |r|
                Observable.find(r).delete
              end
            end
          end
        end
      end
    end
  end
end
