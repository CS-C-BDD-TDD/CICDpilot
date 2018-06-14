class SocketAddressSerializer < Serializer
  attributes  :cybox_object_id,
              :addresses_normalized_cache,
              :ports_normalized_cache,
              :hostnames_normalized_cache,
              :created_at,
              :updated_at,
              :guid,
              :portion_marking,
              :read_only,
              :is_ciscp,
              :is_mifr,
              :feeds,
              :total_sightings

  associate :badge_statuses do single? end
  node :indicators, ->{single?} do |sa|
    array = []
    sa.indicators.each do |i|
      hsh = i.as_json(single: false)
      
      hsh[:acs_set] = i.acs_set.present? ? {id: i.acs_set.guid, name: i.acs_set.name, portion_marking: i.acs_set.portion_marking} : nil
    
      array << hsh
    end
    array
  end

  associate :course_of_actions do single? end

  associate :ind_course_of_actions, {
    except: [
      :id, 
      :stix_timestamp, 
      :created_by_user_guid, 
      :updated_by_user_guid, 
      :created_by_organization_guid, 
      :updated_by_organization_guid
    ]
  } do single? end

  associate :addresses do single? end

  node :hostnames, ->{single?} do |sa|
    array = []
    sa.hostnames.each do |h|
      hsh = h.as_json(single: false)
      hsh[:hostname_input] = h.hostname_input

      array << hsh
    end
    array
  end

  associate :ports do single? end

  associate :stix_markings, {
    include: [
      isa_marking_structure: {except: :stix_marking_id},
      isa_assertion_structure: {
        except: [:stix_marking_id, :sharing_default],
        include: [
          isa_privs: {only: [:action, :effect, :id]}, 
          further_sharings: {}
        ]
      },
      tlp_marking_structure: {only: [:id, :stix_id, :color, :guid]},
      simple_marking_structure: {only: [:id, :consent, :guid, :color, :proprietary]},
      ais_consent_marking_structure: {except: [:stix_id, :stix_marking_id]}
    ]
  } do single? end

  associate :audits, {
    except: [
      :id, 
      :old_justification, 
      :audit_subtype, 
      :item_type_audited, 
      :item_guid_audited, 
      :guid
    ],
    include: [
      user: {
        only: [:guid, :username, :id]
      }
    ]
  } do single? end

  node :network_connections, -> {single?} do |x|
    net = []
    net.push(x.network_connection_sources) if x.network_connection_sources.present?
    net.push(x.network_connection_destinations) if x.network_connection_destinations.present?

    s = net.flatten.collect do |s|
    {
      cybox_object_id: s.cybox_object_id,
      dest_socket_address: s.dest_socket_address,
      dest_socket_hostname: s.dest_socket_hostname,
      dest_socket_is_spoofed: s.dest_socket_is_spoofed,
      dest_socket_port: s.dest_socket_port,
      source_socket_address: s.source_socket_address,
      source_socket_hostname: s.source_socket_hostname,
      source_socket_is_spoofed: s.source_socket_is_spoofed,
      source_socket_port: s.source_socket_port,
      layer3_protocol: s.layer3_protocol,
      layer4_protocol: s.layer4_protocol,
      layer7_protocol: s.layer7_protocol,
      created_at: s.created_at,
      updated_at: s.updated_at,
      guid: s.guid,
      portion_marking: s.portion_marking,
      read_only: s.read_only,
      dest_socket_address_c: s.dest_socket_address_c,
      dest_socket_port_c: s.dest_socket_port_c,
      source_socket_address_c: s.source_socket_address_c,
      source_socket_port_c: s.source_socket_port_c,
      layer3_protocol_c: s.layer3_protocol_c,
      layer4_protocol_c: s.layer4_protocol_c,
      layer7_protocol_c: s.layer7_protocol_c,
      dest_socket_hostname_c: s.dest_socket_hostname_c,
      source_socket_hostname_: s.source_socket_hostname_c
    }
    end

    s
  end

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