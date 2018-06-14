class Public::UriSerializer < Serializer
  attributes :cybox_hash,
             :cybox_object_id,
             :label,
             :uri_raw,
             :uri_type
end