class AddUpdatedAtIndexes < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.column_exists?(:contributing_sources,:updated_at)
      add_column :contributing_sources,:created_at,:timestamp
      add_column :contributing_sources,:updated_at,:timestamp
    end
    if !ActiveRecord::Base.connection.index_exists?(:ais_statistics,:updated_at)
      add_index :ais_statistics,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:attack_patterns,:updated_at)
      add_index :attack_patterns,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:avp_messages,:updated_at)
      add_index :avp_messages,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:contributing_sources,:updated_at)
      add_index :contributing_sources,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:course_of_actions,:updated_at)
      add_index :course_of_actions,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_addresses,:updated_at)
      add_index :cybox_addresses,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_dns_queries,:updated_at)
      add_index :cybox_dns_queries,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_dns_records,:updated_at)
      add_index :cybox_dns_records,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_domains,:updated_at)
      add_index :cybox_domains,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_email_messages,:updated_at)
      add_index :cybox_email_messages,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_files,:updated_at)
      add_index :cybox_files,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_hostnames,:updated_at)
      add_index :cybox_hostnames,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_http_sessions,:updated_at)
      add_index :cybox_http_sessions,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_links,:updated_at)
      add_index :cybox_links,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_mutexes,:updated_at)
      add_index :cybox_mutexes,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_network_connections,:updated_at)
      add_index :cybox_network_connections,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_observables,:updated_at)
      add_index :cybox_observables,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_ports,:updated_at)
      add_index :cybox_ports,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_socket_addresses,:updated_at)
      add_index :cybox_socket_addresses,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_uris,:updated_at)
      add_index :cybox_uris,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:cybox_win_registry_keys,:updated_at)
      add_index :cybox_win_registry_keys,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:exploit_targets,:updated_at)
      add_index :exploit_targets,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:exported_indicators,:updated_at)
      add_index :exported_indicators,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:layer_seven_connections,:updated_at)
      add_index :layer_seven_connections,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:parameter_observables,:updated_at)
      add_index :parameter_observables,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:questions,:updated_at)
      add_index :questions,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:resource_records,:updated_at)
      add_index :resource_records,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:stix_indicators,:updated_at)
      add_index :stix_indicators,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:stix_markings,:updated_at)
      add_index :stix_markings,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:stix_packages,:updated_at)
      add_index :stix_packages,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:threat_actors,:updated_at)
      add_index :threat_actors,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:ttps,:updated_at)
      add_index :ttps,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:uploaded_files,:updated_at)
      add_index :uploaded_files,:updated_at
    end
    if !ActiveRecord::Base.connection.index_exists?(:vulnerabilities,:updated_at)
      add_index :vulnerabilities,:updated_at
    end
    if !ActiveRecord::Base.connection.table_exists?(:solr_index_time)
      create_table :solr_index_time do |t|
        t.timestamp :last_updated
      end
    end
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:contributing_sources,:updated_at)
      remove_column :contributing_sources,:created_at
      remove_column :contributing_sources,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:ais_statistics,:updated_at)
      remove_index :ais_statistics,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:attack_patterns,:updated_at)
      remove_index :attack_patterns,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:avp_messages,:updated_at)
      remove_index :avp_messages,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:contributing_sources,:updated_at)
      remove_index :contributing_sources,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:course_of_actions,:updated_at)
      remove_index :course_of_actions,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_addresses,:updated_at)
      remove_index :cybox_addresses,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_dns_queries,:updated_at)
      remove_index :cybox_dns_queries,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_dns_records,:updated_at)
      remove_index :cybox_dns_records,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_domains,:updated_at)
      remove_index :cybox_domains,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_email_messages,:updated_at)
      remove_index :cybox_email_messages,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_files,:updated_at)
      remove_index :cybox_files,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_hostnames,:updated_at)
      remove_index :cybox_hostnames,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_http_sessions,:updated_at)
      remove_index :cybox_http_sessions,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_links,:updated_at)
      remove_index :cybox_links,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_mutexes,:updated_at)
      remove_index :cybox_mutexes,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_network_connections,:updated_at)
      remove_index :cybox_network_connections,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_observables,:updated_at)
      remove_index :cybox_observables,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_ports,:updated_at)
      remove_index :cybox_ports,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_socket_addresses,:updated_at)
      remove_index :cybox_socket_addresses,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_uris,:updated_at)
      remove_index :cybox_uris,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:cybox_win_registry_keys,:updated_at)
      remove_index :cybox_win_registry_keys,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:exploit_targets,:updated_at)
      remove_index :exploit_targets,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:exported_indicators,:updated_at)
      remove_index :exported_indicators,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:layer_seven_connections,:updated_at)
      remove_index :layer_seven_connections,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:parameter_observables,:updated_at)
      remove_index :parameter_observables,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:questions,:updated_at)
      remove_index :questions,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:resource_records,:updated_at)
      remove_index :resource_records,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:stix_indicators,:updated_at)
      remove_index :stix_indicators,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:stix_markings,:updated_at)
      remove_index :stix_markings,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:stix_packages,:updated_at)
      remove_index :stix_packages,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:threat_actors,:updated_at)
      remove_index :threat_actors,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:ttps,:updated_at)
      remove_index :ttps,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:uploaded_files,:updated_at)
      remove_index :uploaded_files,:updated_at
    end
    if ActiveRecord::Base.connection.index_exists?(:vulnerabilities,:updated_at)
      remove_index :vulnerabilities,:updated_at
    end
    if ActiveRecord::Base.connection.table_exists?(:solr_index_time)
      drop_table :solr_index_time
    end
  end
end
