class PortionMarkingCacheColumn < ActiveRecord::Migration
  def change
    add_column :stix_packages,:portion_marking,:string
    add_column :stix_indicators,:portion_marking,:string
    add_column :cybox_domains,:portion_marking,:string
    add_column :cybox_email_messages,:portion_marking,:string
    add_column :cybox_files,:portion_marking,:string
    add_column :cybox_addresses,:portion_marking,:string
    add_column :cybox_mutexes,:portion_marking,:string
    add_column :cybox_links,:portion_marking,:string
    add_column :cybox_win_registry_keys,:portion_marking,:string
    add_column :cybox_network_connections,:portion_marking,:string
    add_column :cybox_dns_records,:portion_marking,:string
    add_column :cybox_uris,:portion_marking,:string
    add_column :cybox_http_sessions,:portion_marking,:string
  end
end
