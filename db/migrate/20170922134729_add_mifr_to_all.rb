class AddMifrToAll < ActiveRecord::Migration
  def change
  	# Adding MIFR boolean column to all the tables that need it.
  	add_column :stix_indicators, :is_mifr, :boolean, :default => false
  	add_column :exploit_targets, :is_mifr, :boolean, :default => false
  	add_column :ttps, :is_mifr, :boolean, :default => false
  	add_column :course_of_actions, :is_mifr, :boolean, :default => false
  	add_column :cybox_addresses, :is_mifr, :boolean, :default => false
  	add_column :cybox_dns_queries, :is_mifr, :boolean, :default => false
  	add_column :cybox_dns_records, :is_mifr, :boolean, :default => false
  	add_column :cybox_domains, :is_mifr, :boolean, :default => false
  	add_column :cybox_email_messages, :is_mifr, :boolean, :default => false
  	add_column :cybox_files, :is_mifr, :boolean, :default => false
  	add_column :cybox_hostnames, :is_mifr, :boolean, :default => false
  	add_column :cybox_http_sessions, :is_mifr, :boolean, :default => false
  	add_column :cybox_links, :is_mifr, :boolean, :default => false
  	add_column :cybox_mutexes, :is_mifr, :boolean, :default => false
  	add_column :cybox_network_connections, :is_mifr, :boolean, :default => false
  	add_column :cybox_ports, :is_mifr, :boolean, :default => false
  	add_column :cybox_win_registry_keys, :is_mifr, :boolean, :default => false
  	add_column :cybox_socket_addresses, :is_mifr, :boolean, :default => false
  	add_column :cybox_uris, :is_mifr, :boolean, :default => false
    add_column :stix_packages, :is_mifr, :boolean, :default => false
    add_column :cybox_observables, :is_mifr, :boolean, :default => false
    add_column :cybox_file_hashes, :is_mifr, :boolean, :default => false
  	add_column :questions, :is_mifr, :boolean, :default => false
  	add_column :resource_records, :is_mifr, :boolean, :default => false  	
  end
end
