class Layer4ProtocolDataMigration < ActiveRecord::Migration
  class ANetworkConnection < ActiveRecord::Base
    self.table_name = 'cybox_network_connections'
  end

  def up
    ANetworkConnection.reset_column_information

    ANetworkConnection.all.each { |nc|
      nc.layer4_protocol =
          nc.old_dest_socket_protocol.present? ? nc.old_dest_socket_protocol
          : nc.old_source_socket_protocol
      nc.save
    }
  end

  def down
    ANetworkConnection.reset_column_information

    ANetworkConnection.all.each { |nc|
      if nc.old_dest_socket_protocol.nil? && nc.old_source_socket_protocol.nil?
        nc.old_dest_socket_protocol =
            nc.old_source_socket_protocol = nc.layer4_protocol
        nc.save
      end
    }
  end
end
