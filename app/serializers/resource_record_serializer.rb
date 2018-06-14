class ResourceRecordSerializer < Serializer
  attributes :guid,
             :cybox_hash,
             :portion_marking,
             :record_type,
             :dns_record_cache,
             :created_at,
             :updated_at,
             :is_reference,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds

  associate :badge_statuses do single? end
  associate :audits, {include: [user: {only: [:username,:guid,:id]}]} do single? end
  associate :dns_records do single? end
  associate :dns_queries do single? end
  associate :stix_packages do single? end
end