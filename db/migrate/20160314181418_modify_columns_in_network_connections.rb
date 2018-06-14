class ModifyColumnsInNetworkConnections < ActiveRecord::Migration
  def change
    add_column :cybox_network_connections, :dest_socket_hostname, :string
    add_column :cybox_network_connections, :source_socket_hostname, :string
    add_column :cybox_network_connections, :layer3_protocol, :string
    add_column :cybox_network_connections, :layer4_protocol, :string
    add_column :cybox_network_connections, :layer7_protocol, :string
    rename_column :cybox_network_connections, :dest_socket_protocol,
        :old_dest_socket_protocol
    rename_column :cybox_network_connections, :source_socket_protocol,
        :old_source_socket_protocol
  end
end
