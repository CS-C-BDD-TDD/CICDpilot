class Public::AddressSerializer < Serializer
  attributes :address_value_raw,
             :cybox_hash,
             :cybox_object_id,
             :category
end