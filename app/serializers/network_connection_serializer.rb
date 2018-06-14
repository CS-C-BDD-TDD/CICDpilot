class NetworkConnectionSerializer < Serializer
  attributes  :cybox_object_id,
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
              :layer7_protocol,
              :created_at,
              :updated_at,
              :guid,
              :portion_marking,
              :read_only,
              :dest_socket_address_c,
              :dest_socket_port_c,
              :source_socket_address_c,
              :source_socket_port_c,
              :layer3_protocol_c,
              :layer4_protocol_c,
              :layer7_protocol_c,
              :dest_socket_hostname_c,
              :source_socket_hostname_c,
              :display_name,
              :is_ciscp,
              :is_mifr,
              :feeds,
              :total_sightings

  associate :badge_statuses do single? end
  node :stix_markings, ->{single?} do |network_connection|
    if network_connection.class == NetworkConnection
      stix_markings = network_connection.stix_markings
      stix_markings
    end
  end

  node :socket_addresses, -> {single?} do |network_connection|
    socket_addresses = []
    socket_addresses.push(network_connection.source_socket_address_obj) if network_connection.source_socket_address_obj.present?
    socket_addresses.push(network_connection.dest_socket_address_obj) if network_connection.dest_socket_address_obj.present?

    s = socket_addresses.collect do |s|
    {
      type: (network_connection.source_socket_address_obj.present? && s.cybox_object_id == network_connection.source_socket_address_obj.cybox_object_id) ? "source" : "dest",
      cybox_object_id: s.cybox_object_id,
      addresses_normalized_cache: s.addresses_normalized_cache,
      ports_normalized_cache: s.ports_normalized_cache,
      hostnames_normalized_cache: s.hostnames_normalized_cache,
      created_at: s.created_at,
      updated_at: s.updated_at,
      guid: s.guid,
      portion_marking: s.portion_marking,
      read_only: s.read_only,
      stix_markings: s.stix_markings,
      addresses: s.addresses
    }
    end
    s
  end
  
  associate :layer_seven_connections, {except: :guid, include: [:http_session, :dns_queries]} do single? end
  associate :indicators do single? end
  associate :course_of_actions do single? end
  associate :ind_course_of_actions do single? end
  associate :audits, {include: [user: {only: [:username,:guid,:id]}]} do single? end

  associate :stix_packages, {
    except: :id, 
    include: [badge_statuses: {
      except: [
        :guid,
        :remote_object_id,
        :remote_object_type,
        :system,
        :created_at,
        :updated_at
      ]
    }]
  } do single? end
end
