class Public::MutexSerializer < Serializer
  attributes :cybox_object_id,
             :cybox_hash,
             :name,
             :name_condition
end