class Public::IndicatorSerializer < Serializer
  attributes :composite_operator,
             :description,
             :indicator_type,
             :indicator_type_vocab_name,
             :indicator_type_vocab_ref,
             :is_composite,
             :is_negated,
             :is_reference,
             :parent_id,
             :resp_entity_stix_ident_id,
             :stix_id,
             :dms_label,
             :stix_timestamp,
             :title,
             :guid,
             :downgrade_request_id,
             :reference


  associate :observables, {as: 'observables_attributes', except: :id, include: [
      address: {as: 'address_attributes', serializer: Public::AddressSerializer},
      domain: {as: 'domain_attributes', serializer: Public::DomainSerializer},
      dns_record: {as: 'dns_record_attributes', serializer: Public::DnsRecordSerializer},
      email_message: {as: 'email_message_attributes', serializer: Public::EmailMessageSerializer},
      uri: {as: 'uri_attributes', serializer: Public::UriSerializer},
      mutex: {as: 'mutex_attributes', class_name: CyboxMutex, serializer: Public::MutexSerializer},
      http_session: {as: 'http_session_attributes', serializer: Public::HttpSessionSerializer},
      hostname: {as: 'hostname_attributes', serializer: Public::HostnameSerializer},
      port: {as: 'port_attributes', serializer: Public::PortSerializer},
      network_connection: {as: 'network_connection_attributes', serializer: Public::NetworkConnectionSerializer},
      registry: {as: 'registry_attributes', serializer: Public::RegistrySerializer, include: [
          registry_values: {as: 'registry_values_attributes', serializer: Public::RegistryValueSerializer}
      ]},
      file: {as: 'file_attributes', class_name: CyboxFile, serializer: Public::FileSerializer, include: [
          file_hashes: {as: 'file_hashes_attributes', serializer: Public::FileHashSerializer}
      ]}
  ]}
  associate :stix_markings, {as: 'stix_markings_attributes', except: :id, include: [
      isa_marking_structures: {as: 'isa_marking_structures_attributes',except: :id}
  ]}

  associate :weather_map_addresses, { as: 'weather_map_addresses_attributes', except: :id}

  associate :weather_map_domains, { as: 'weather_map_domains_attributes', except: :id}

  associate :official_confidence, {as: 'confidences_attributes', class_name: Confidence, except: :id}
end
