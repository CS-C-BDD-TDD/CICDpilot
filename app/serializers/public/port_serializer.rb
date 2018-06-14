class Public::PortSerializer < Serializer
  attributes :port,
             :layer4_protocol,
             :cybox_hash,
             :cybox_object_id
end