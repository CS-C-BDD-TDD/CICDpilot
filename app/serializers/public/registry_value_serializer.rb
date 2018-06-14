class Public::RegistryValueSerializer < Serializer
  attributes :cybox_object_id,
             :reg_name,
             :cybox_hash,
             :reg_value
end