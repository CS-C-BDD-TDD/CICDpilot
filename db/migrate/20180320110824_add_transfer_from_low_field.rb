class AddTransferFromLowField < ActiveRecord::Migration
  def up
    # Add transfer_from_low field, where needed
    unless ActiveRecord::Base.connection.column_exists?(:acs_sets, :transfer_from_low)
      add_column :acs_sets, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :transfer_from_low)
      add_column :acs_sets_organizations, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:ais_consent_marking_structures, :transfer_from_low)
      add_column :ais_consent_marking_structures, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:badge_statuses, :transfer_from_low)
      add_column :badge_statuses, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:contributing_sources, :transfer_from_low)
      add_column :contributing_sources, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:dns_query_questions, :transfer_from_low)
      add_column :dns_query_questions, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:dns_query_resource_records, :transfer_from_low)
      add_column :dns_query_resource_records, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_files, :transfer_from_low)
      add_column :email_files, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_links, :transfer_from_low)
      add_column :email_links, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_uris, :transfer_from_low)
      add_column :email_uris, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:error_messages, :transfer_from_low)
      add_column :error_messages, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:exploit_target_coas, :transfer_from_low)
      add_column :exploit_target_coas, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:exploit_target_packages, :transfer_from_low)
      add_column :exploit_target_packages, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:exploit_target_vulnerabilities, :transfer_from_low)
      add_column :exploit_target_vulnerabilities, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:exported_indicators, :transfer_from_low)
      add_column :exported_indicators, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:further_sharings, :transfer_from_low)
      add_column :further_sharings, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:indicators_course_of_actions, :transfer_from_low)
      add_column :indicators_course_of_actions, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:indicators_threat_actors, :transfer_from_low)
      add_column :indicators_threat_actors, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:indicator_ttps, :transfer_from_low)
      add_column :indicator_ttps, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_assertion_structures, :transfer_from_low)
      add_column :isa_assertion_structures, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_entity_caches, :transfer_from_low)
      add_column :isa_entity_caches, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_marking_structures, :transfer_from_low)
      add_column :isa_marking_structures, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_privs, :transfer_from_low)
      add_column :isa_privs, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:lsc_dns_queries, :transfer_from_low)
      add_column :lsc_dns_queries, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:nc_layer_seven_connections, :transfer_from_low)
      add_column :nc_layer_seven_connections, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:notes, :transfer_from_low)
      add_column :notes, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:original_input, :transfer_from_low)
      add_column :original_input, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:organizations, :transfer_from_low)
      add_column :organizations, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:packages_course_of_actions, :transfer_from_low)
      add_column :packages_course_of_actions, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:question_uris, :transfer_from_low)
      add_column :question_uris, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:resource_record_dns_records, :transfer_from_low)
      add_column :resource_record_dns_records, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:simple_structures, :transfer_from_low)
      add_column :simple_structures, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:socket_address_addresses, :transfer_from_low)
      add_column :socket_address_addresses, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:socket_address_hostnames, :transfer_from_low)
      add_column :socket_address_hostnames, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:socket_address_ports, :transfer_from_low)
      add_column :socket_address_ports, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_confidences, :transfer_from_low)
      add_column :stix_confidences, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_indicators_packages, :transfer_from_low)
      add_column :stix_indicators_packages, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_kill_chain_phases, :transfer_from_low)
      add_column :stix_kill_chain_phases, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_kill_chain_refs, :transfer_from_low)
      add_column :stix_kill_chain_refs, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_kill_chains, :transfer_from_low)
      add_column :stix_kill_chains, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_markings, :transfer_from_low)
      add_column :stix_markings, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_related_objects, :transfer_from_low)
      add_column :stix_related_objects, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_sightings, :transfer_from_low)
      add_column :stix_sightings, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:tag_assignments, :transfer_from_low)
      add_column :tag_assignments, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:tags, :transfer_from_low)
      add_column :tags, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:tlp_structures, :transfer_from_low)
      add_column :tlp_structures, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:ttp_attack_patterns, :transfer_from_low)
      add_column :ttp_attack_patterns, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:ttp_exploit_targets, :transfer_from_low)
      add_column :ttp_exploit_targets, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:ttp_packages, :transfer_from_low)
      add_column :ttp_packages, :transfer_from_low, :boolean, :default => false
    end
    unless ActiveRecord::Base.connection.column_exists?(:users, :transfer_from_low)
      add_column :users, :transfer_from_low, :boolean, :default => false
    end
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:acs_sets, :transfer_from_low)
      remove_column :acs_sets, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :transfer_from_low)
      remove_column :acs_sets_organizations, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:ais_consent_marking_structures, :transfer_from_low)
      remove_column :ais_consent_marking_structures, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:badge_statuses, :transfer_from_low)
      remove_column :badge_statuses, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:contributing_sources, :transfer_from_low)
      remove_column :contributing_sources, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:dns_query_questions, :transfer_from_low)
      remove_column :dns_query_questions, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:dns_query_resource_records, :transfer_from_low)
      remove_column :dns_query_resource_records, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:email_files, :transfer_from_low)
      remove_column :email_files, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:email_links, :transfer_from_low)
      remove_column :email_links, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:email_uris, :transfer_from_low)
      remove_column :email_uris, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:error_messages, :transfer_from_low)
      remove_column :error_messages, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:exploit_target_coas, :transfer_from_low)
      remove_column :exploit_target_coas, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:exploit_target_packages, :transfer_from_low)
      remove_column :exploit_target_packages, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:exploit_target_vulnerabilities, :transfer_from_low)
      remove_column :exploit_target_vulnerabilities, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:exported_indicators, :transfer_from_low)
      remove_column :exported_indicators, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:further_sharings, :transfer_from_low)
      remove_column :further_sharings, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:indicators_course_of_actions, :transfer_from_low)
      remove_column :indicators_course_of_actions, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:indicators_threat_actors, :transfer_from_low)
      remove_column :indicators_threat_actors, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:indicator_ttps, :transfer_from_low)
      remove_column :indicator_ttps, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_assertion_structures, :transfer_from_low)
      remove_column :isa_assertion_structures, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_entity_caches, :transfer_from_low)
      remove_column :isa_entity_caches, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_marking_structures, :transfer_from_low)
      remove_column :isa_marking_structures, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_privs, :transfer_from_low)
      remove_column :isa_privs, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:lsc_dns_queries, :transfer_from_low)
      remove_column :lsc_dns_queries, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:nc_layer_seven_connections, :transfer_from_low)
      remove_column :nc_layer_seven_connections, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:notes, :transfer_from_low)
      remove_column :notes, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:original_input, :transfer_from_low)
      remove_column :original_input, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:organizations, :transfer_from_low)
      remove_column :organizations, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:packages_course_of_actions, :transfer_from_low)
      remove_column :packages_course_of_actions, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:question_uris, :transfer_from_low)
      remove_column :question_uris, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:resource_record_dns_records, :transfer_from_low)
      remove_column :resource_record_dns_records, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:simple_structures, :transfer_from_low)
      remove_column :simple_structures, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:socket_address_addresses, :transfer_from_low)
      remove_column :socket_address_addresses, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:socket_address_hostnames, :transfer_from_low)
      remove_column :socket_address_hostnames, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:socket_address_ports, :transfer_from_low)
      remove_column :socket_address_ports, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_confidences, :transfer_from_low)
      remove_column :stix_confidences, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_indicators_packages, :transfer_from_low)
      remove_column :stix_indicators_packages, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_kill_chain_phases, :transfer_from_low)
      remove_column :stix_kill_chain_phases, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_kill_chain_refs, :transfer_from_low)
      remove_column :stix_kill_chain_refs, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_kill_chains, :transfer_from_low)
      remove_column :stix_kill_chains, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_markings, :transfer_from_low)
      remove_column :stix_markings, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_related_objects, :transfer_from_low)
      remove_column :stix_related_objects, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_sightings, :transfer_from_low)
      remove_column :stix_sightings, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:tag_assignments, :transfer_from_low)
      remove_column :tag_assignments, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:tags, :transfer_from_low)
      remove_column :tags, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:tlp_structures, :transfer_from_low)
      remove_column :tlp_structures, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:ttp_attack_patterns, :transfer_from_low)
      remove_column :ttp_attack_patterns, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:ttp_exploit_targets, :transfer_from_low)
      remove_column :ttp_exploit_targets, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:ttp_packages, :transfer_from_low)
      remove_column :ttp_packages, :transfer_from_low
    end
    if ActiveRecord::Base.connection.column_exists?(:users, :transfer_from_low)
      remove_column :users, :transfer_from_low
    end
  end
end


