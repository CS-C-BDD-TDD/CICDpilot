class Public::HostnameSerializer < Serializer
  attributes :hostname_raw,
             :hostname_condition,
             :naming_system,
             :cybox_hash,
             :cybox_object_id,
             :is_domain_name
end