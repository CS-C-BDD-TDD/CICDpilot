class FixStixid < ActiveRecord::Migration


  def up
  migrator = Proc.new { |pair| 
    (table,column) = pair.split('.')

    class_name = "#{table.classify}Mig"
    if !Object.const_defined?(class_name)
      Object.const_set(class_name,Class.new(ActiveRecord::Base) { self.table_name = table })
    end
    dynamic = class_name.constantize
    dynamic.all.each do |object|
      value = object.send(column)
      if (value||"").starts_with?(':')
        object.send("#{column}=","NCCIC#{value}")
        object.save
      end
    end
  }

    stix_ids = %w{cybox_observables.stix_indicator_id
    stix_confidences.remote_object_id
    stix_indicators.stix_id
    stix_indicators_packages.stix_indicator_id
    stix_indicators_packages.stix_package_id
    stix_kill_chains.remote_object_id
    stix_markings.remote_object_id
    stix_packages.stix_id
    stix_sightings.stix_indicator_id}

    cybox_object_ids = %w{
      cybox_addresses.cybox_object_id
      cybox_custom_objects.cybox_object_id
      cybox_dns_records.cybox_object_id
      cybox_domains.cybox_object_id
      cybox_email_messages.cybox_object_id
      cybox_email_messages.from_cybox_object_id
      cybox_email_messages.reply_to_cybox_object_id
      cybox_email_messages.sender_cybox_object_id
      cybox_file_hashes.cybox_object_id
      cybox_files.cybox_object_id
      cybox_http_sessions.cybox_object_id
      cybox_mutexes.cybox_object_id
      cybox_network_connections.cybox_object_id
      cybox_observables.cybox_object_id
      cybox_observables.remote_object_id
      cybox_uris.cybox_object_id
      cybox_win_registry_keys.cybox_object_id
      cybox_win_registry_values.cybox_win_reg_key_id
    }



    stix_ids.each &migrator
    cybox_object_ids.each &migrator

  end

  def down
  reverse_migrator = Proc.new { |pair| 
      (table,column) = pair.split('.')

      class_name = "#{table.classify}Mig"
      if !Object.const_defined?(class_name)
        Object.const_set(class_name,Class.new(ActiveRecord::Base) { self.table_name = table })
      end

      dynamic = class_name.constantize
      dynamic.all.each do |object|
        value = object.send(column)
        if (value||"").starts_with?('NCCIC:')
          new_value = value.gsub(/^NCCIC:/,':')
          object.send("#{column}=",new_value)
          object.save
        end
      end
    }

    stix_ids = %w{cybox_observables.stix_indicator_id
                  stix_confidences.remote_object_id
                  stix_indicators.stix_id
                  stix_indicators_packages.stix_indicator_id
                  stix_indicators_packages.stix_package_id
                  stix_kill_chains.remote_object_id
                  stix_markings.remote_object_id
                  stix_packages.stix_id
                  stix_sightings.stix_indicator_id}

    cybox_object_ids = %w{
      cybox_addresses.cybox_object_id
      cybox_custom_objects.cybox_object_id
      cybox_dns_records.cybox_object_id
      cybox_domains.cybox_object_id
      cybox_email_messages.cybox_object_id
      cybox_email_messages.from_cybox_object_id
      cybox_email_messages.reply_to_cybox_object_id
      cybox_email_messages.sender_cybox_object_id
      cybox_file_hashes.cybox_object_id
      cybox_files.cybox_object_id
      cybox_http_sessions.cybox_object_id
      cybox_mutexes.cybox_object_id
      cybox_network_connections.cybox_object_id
      cybox_observables.cybox_object_id
      cybox_observables.remote_object_id
      cybox_uris.cybox_object_id
      cybox_win_registry_keys.cybox_object_id
      cybox_win_registry_values.cybox_win_reg_key_id
    }

    stix_ids.each &reverse_migrator
    cybox_object_ids.each &reverse_migrator

  end
end
