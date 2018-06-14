class AddCiscpBooleanToManyTables < ActiveRecord::Migration
  def change
  	add_column :stix_indicators, :is_ciscp, :boolean, :default => false
  	add_column :exploit_targets, :is_ciscp, :boolean, :default => false
  	add_column :ttps, :is_ciscp, :boolean, :default => false
  	add_column :course_of_actions, :is_ciscp, :boolean, :default => false
  	add_column :cybox_addresses, :is_ciscp, :boolean, :default => false
  	add_column :cybox_dns_queries, :is_ciscp, :boolean, :default => false
  	add_column :cybox_dns_records, :is_ciscp, :boolean, :default => false
  	add_column :cybox_domains, :is_ciscp, :boolean, :default => false
  	add_column :cybox_email_messages, :is_ciscp, :boolean, :default => false
  	add_column :cybox_files, :is_ciscp, :boolean, :default => false
  	add_column :cybox_hostnames, :is_ciscp, :boolean, :default => false
  	add_column :cybox_http_sessions, :is_ciscp, :boolean, :default => false
  	add_column :cybox_links, :is_ciscp, :boolean, :default => false
  	add_column :cybox_mutexes, :is_ciscp, :boolean, :default => false
  	add_column :cybox_network_connections, :is_ciscp, :boolean, :default => false
  	add_column :cybox_ports, :is_ciscp, :boolean, :default => false
  	add_column :cybox_win_registry_keys, :is_ciscp, :boolean, :default => false
  	add_column :cybox_socket_addresses, :is_ciscp, :boolean, :default => false
  	add_column :cybox_uris, :is_ciscp, :boolean, :default => false
  end
end
