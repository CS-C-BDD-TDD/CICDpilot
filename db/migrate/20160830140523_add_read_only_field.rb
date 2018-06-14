class AddReadOnlyField < ActiveRecord::Migration
  def change
    add_column :uploaded_files, :read_only, :boolean, :default => false
    add_column :stix_packages, :read_only, :boolean, :default => false
    add_column :stix_indicators, :read_only, :boolean, :default => false
    add_column :cybox_addresses, :read_only, :boolean, :default => false
    add_column :cybox_dns_records, :read_only, :boolean, :default => false
    add_column :cybox_domains, :read_only, :boolean, :default => false
    add_column :cybox_email_messages, :read_only, :boolean, :default => false
    add_column :cybox_file_hashes, :read_only, :boolean, :default => false
    add_column :cybox_files, :read_only, :boolean, :default => false
    add_column :cybox_http_sessions, :read_only, :boolean, :default => false
    add_column :cybox_links, :read_only, :boolean, :default => false
    add_column :cybox_mutexes, :read_only, :boolean, :default => false
    add_column :cybox_network_connections, :read_only, :boolean, :default => false
    add_column :cybox_observables, :read_only, :boolean, :default => false
    add_column :cybox_win_registry_keys, :read_only, :boolean, :default => false
    add_column :cybox_win_registry_values, :read_only, :boolean, :default => false
    add_column :cybox_uris, :read_only, :boolean, :default => false
  end
end
