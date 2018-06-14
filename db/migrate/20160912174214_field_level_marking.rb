class FieldLevelMarking < ActiveRecord::Migration
  class MStixMarking < ActiveRecord::Base; self.table_name = :stix_markings; end

  def up
    MStixMarking.class_eval do
      belongs_to :remote_object,
                 primary_key: :stix_id,
                 foreign_key: :remote_object_id,
                 foreign_type: :remote_object_type,
                 polymorphic: true
    end

    MStixMarking.all.find_in_batches do |group|
      group.each do |sm|
        if (sm.remote_object != nil)
            id = sm.remote_object.guid
            sm.update_columns({remote_object_id: id})
        end
      end
    end

    add_column :stix_markings,:remote_object_field,:string

    add_column :stix_packages,:title_c,:string
    add_column :stix_packages,:description_c,:string
    add_column :stix_packages,:short_description_c,:string
    add_column :stix_packages,:package_intent_c,:string

    add_column :stix_indicators,:title_c,:string
    add_column :stix_indicators,:description_c,:string
    add_column :stix_indicators,:indicator_type_c,:string
    add_column :stix_indicators,:dms_label_c,:string
    add_column :stix_indicators,:downgrade_request_id_c,:string
    add_column :stix_indicators,:reference_c,:string
    add_column :stix_indicators,:alternative_id_c,:string

    add_column :cybox_addresses, :address_value_normalized_c,:string

    add_column :cybox_dns_records,:address_value_normalized_c,:string
    add_column :cybox_dns_records,:address_class_c,:string
    add_column :cybox_dns_records,:domain_normalized_c,:string
    add_column :cybox_dns_records,:entry_type_c,:string
    add_column :cybox_dns_records,:queried_date_c,:string

    add_column :cybox_domains,:name_normalized_c,:string

    add_column :cybox_email_messages,:from_normalized_c,:string
    add_column :cybox_email_messages,:sender_normalized_c,:string
    add_column :cybox_email_messages,:reply_to_normalized_c,:string
    add_column :cybox_email_messages,:subject_c,:string
    add_column :cybox_email_messages,:email_date_c,:string
    add_column :cybox_email_messages,:raw_body_c,:string
    add_column :cybox_email_messages,:raw_header_c,:string
    add_column :cybox_email_messages,:message_id_c,:string
    add_column :cybox_email_messages,:x_mailer_c,:string
    add_column :cybox_email_messages,:x_originating_ip_c,:string

    add_column :cybox_files,:file_name_c,:string
    add_column :cybox_files,:file_path_c,:string
    add_column :cybox_files,:size_in_bytes_c,:string

    add_column :cybox_file_hashes,:simple_hash_value_normalized_c,:string
    add_column :cybox_file_hashes,:fuzzy_hash_value_normalized_c,:string

    add_column :cybox_http_sessions,:user_agent_c,:string
    add_column :cybox_http_sessions,:domain_name_c,:string
    add_column :cybox_http_sessions,:port_c,:string
    add_column :cybox_http_sessions,:referer_c,:string
    add_column :cybox_http_sessions,:pragma_c,:string

    add_column :cybox_links,:label_c,:string

    add_column :cybox_uris,:uri_normalized_c,:string

    add_column :cybox_mutexes,:name_c,:string

    add_column :cybox_network_connections,:dest_socket_address_c,:string
    add_column :cybox_network_connections,:dest_socket_port_c,:string
    add_column :cybox_network_connections,:source_socket_address_c,:string
    add_column :cybox_network_connections,:source_socket_port_c,:string
    add_column :cybox_network_connections,:layer3_protocol_c,:string
    add_column :cybox_network_connections,:layer4_protocol_c,:string
    add_column :cybox_network_connections,:layer7_protocol_c,:string

    add_column :cybox_win_registry_keys,:hive_c,:string
    add_column :cybox_win_registry_keys,:key_c,:string
    add_column :cybox_win_registry_values,:reg_name_c,:string
    add_column :cybox_win_registry_values,:reg_value_c,:string
  end

  def down
    MStixMarking.class_eval do
      belongs_to :remote_object,
                 primary_key: :guid,
                 foreign_key: :remote_object_id,
                 foreign_type: :remote_object_type,
                 polymorphic: true
    end

    MStixMarking.all.find_in_batches do |group|
      group.each do |sm|
        if (sm.remote_object != nil)
            id = sm.remote_object.stix_id
            sm.update_columns({remote_object_id: id})
        end
      end
    end

    remove_column :stix_markings,:remote_object_field

    remove_column :stix_packages,:title_c
    remove_column :stix_packages,:description_c
    remove_column :stix_packages,:short_description_c
    remove_column :stix_packages,:package_intent_c

    remove_column :stix_indicators,:title_c
    remove_column :stix_indicators,:description_c
    remove_column :stix_indicators,:indicator_type_c
    remove_column :stix_indicators,:dms_label_c
    remove_column :stix_indicators,:downgrade_request_id_c
    remove_column :stix_indicators,:reference_c
    remove_column :stix_indicators,:alternative_id_c

    remove_column :cybox_addresses, :address_value_normalized_c

    remove_column :cybox_dns_records,:address_value_normalized_c
    remove_column :cybox_dns_records,:address_class_c
    remove_column :cybox_dns_records,:domain_normalized_c
    remove_column :cybox_dns_records,:entry_type_c
    remove_column :cybox_dns_records,:queried_date_c

    remove_column :cybox_domains,:name_normalized_c

    remove_column :cybox_email_messages,:from_normalized_c
    remove_column :cybox_email_messages,:sender_normalized_c
    remove_column :cybox_email_messages,:reply_to_normalized_c
    remove_column :cybox_email_messages,:subject_c
    remove_column :cybox_email_messages,:email_date_c
    remove_column :cybox_email_messages,:raw_body_c
    remove_column :cybox_email_messages,:raw_header_c
    remove_column :cybox_email_messages,:message_id_c
    remove_column :cybox_email_messages,:x_mailer_c
    remove_column :cybox_email_messages,:x_originating_ip_c

    remove_column :cybox_files,:file_name_c
    remove_column :cybox_files,:file_path_c
    remove_column :cybox_files,:size_in_bytes_c

    remove_column :cybox_file_hashes,:simple_hash_value_normalized_c
    remove_column :cybox_file_hashes,:fuzzy_hash_value_normalized_c

    remove_column :cybox_http_sessions,:user_agent_c
    remove_column :cybox_http_sessions,:domain_name_c
    remove_column :cybox_http_sessions,:port_c
    remove_column :cybox_http_sessions,:referer_c
    remove_column :cybox_http_sessions,:pragma_c

    remove_column :cybox_links,:label_c

    remove_column :cybox_uris,:uri_normalized_c

    remove_column :cybox_mutexes,:name_c

    remove_column :cybox_network_connections,:dest_socket_address_c
    remove_column :cybox_network_connections,:dest_socket_port_c
    remove_column :cybox_network_connections,:source_socket_address_c
    remove_column :cybox_network_connections,:source_socket_port_c
    remove_column :cybox_network_connections,:layer3_protocol_c
    remove_column :cybox_network_connections,:layer4_protocol_c
    remove_column :cybox_network_connections,:layer7_protocol_c

    remove_column :cybox_win_registry_keys,:hive_c
    remove_column :cybox_win_registry_keys,:key_c
    remove_column :cybox_win_registry_values,:reg_name_c
    remove_column :cybox_win_registry_values,:reg_value_c
  end
end
