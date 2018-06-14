class CreateNetworkConnections < ActiveRecord::Migration
  def change
    create_table :cybox_network_connections do |t|
      t.string  :cybox_hash
      t.string  :cybox_object_id
      t.string  :dest_socket_address
      t.boolean :dest_socket_is_spoofed, default: false
      t.string  :dest_socket_port
      t.string  :dest_socket_protocol
      t.string  :source_socket_address
      t.boolean :source_socket_is_spoofed, default: false
      t.string  :source_socket_port
      t.string  :source_socket_protocol
      t.string  :guid

      t.timestamps
    end

    add_index :cybox_network_connections, :cybox_object_id
    add_index :cybox_network_connections, :guid
  end
end
