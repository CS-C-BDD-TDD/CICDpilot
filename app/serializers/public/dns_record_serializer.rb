class Public::DnsRecordSerializer < Serializer
  attributes :address_class,
             :address_value_raw,
             :cybox_hash,
             :cybox_object_id,
             :description,
             :domain_raw,
             :entry_type,
             :queried_date
end