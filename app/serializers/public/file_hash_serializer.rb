class Public::FileHashSerializer < Serializer
  attributes :hash_type,
             :hash_condition,
             :simple_hash_value,
             :fuzzy_hash_value,
             :cybox_object_id,
             :cybox_hash
end