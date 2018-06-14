class Public::DomainSerializer < Serializer
  attributes :name_raw,
             :name_condition,
             :cybox_hash,
             :cybox_object_id,
             :name_type
end