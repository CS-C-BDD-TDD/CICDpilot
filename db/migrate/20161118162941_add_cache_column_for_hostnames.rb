class AddCacheColumnForHostnames < ActiveRecord::Migration
  def change
  	add_column :cybox_network_connections,:dest_socket_hostname_c,:string
    add_column :cybox_network_connections,:source_socket_hostname_c,:string
  end
end
