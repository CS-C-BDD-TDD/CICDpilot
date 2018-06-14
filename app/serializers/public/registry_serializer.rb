class Public::RegistrySerializer < Serializer
  attributes :cybox_object_id,
             :cybox_hash,
             :hive,
             :key
end