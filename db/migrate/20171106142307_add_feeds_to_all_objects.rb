class AddFeedsToAllObjects < ActiveRecord::Migration
  def change
    # Adding feeds column to all depending objects
    add_column :stix_indicators, :feeds, :string
    add_column :exploit_targets, :feeds, :string
    add_column :ttps, :feeds, :string
    add_column :course_of_actions, :feeds, :string
    add_column :cybox_addresses, :feeds, :string
    add_column :cybox_dns_queries, :feeds, :string
    add_column :cybox_dns_records, :feeds, :string
    add_column :cybox_domains, :feeds, :string
    add_column :cybox_email_messages, :feeds, :string
    add_column :cybox_files, :feeds, :string
    add_column :cybox_hostnames, :feeds, :string
    add_column :cybox_http_sessions, :feeds, :string
    add_column :cybox_links, :feeds, :string
    add_column :cybox_mutexes, :feeds, :string
    add_column :cybox_network_connections, :feeds, :string
    add_column :cybox_ports, :feeds, :string
    add_column :cybox_win_registry_keys, :feeds, :string
    add_column :cybox_socket_addresses, :feeds, :string
    add_column :cybox_uris, :feeds, :string
    add_column :stix_packages, :feeds, :string
    add_column :cybox_observables, :feeds, :string
    add_column :cybox_file_hashes, :feeds, :string
    add_column :questions, :feeds, :string
    add_column :resource_records, :feeds, :string   
    add_column :vulnerabilities, :feeds, :string
    add_column :threat_actors, :feeds, :string  
    add_column :attack_patterns, :feeds, :string
  end
end

