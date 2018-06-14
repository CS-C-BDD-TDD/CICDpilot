class Public::NetworkConnectionSerializer < Serializer
  attributes :cybox_hash,
      :cybox_object_id,
      :dest_socket_address,
      :dest_socket_hostname,
      :dest_socket_is_spoofed,
      :dest_socket_port,
      :source_socket_address,
      :source_socket_hostname,
      :source_socket_is_spoofed,
      :source_socket_port,
      :layer3_protocol,
      :layer4_protocol,
      :layer7_protocol
end