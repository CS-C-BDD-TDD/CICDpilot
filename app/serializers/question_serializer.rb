class QuestionSerializer < Serializer
  attributes :guid,
             :cybox_hash,
             :portion_marking,
             :qclass,
             :qtype,
             :created_at,
             :updated_at,
             :qname_cache,
             :is_reference,
             :read_only,
             :is_ciscp,
             :is_mifr,
             :feeds

  associate :badge_statuses do single? end
  associate :audits, {include: [user: {only: [:username,:guid,:id]}]} do single? end
  associate :uris do single? end
  associate :dns_queries do single? end
  associate :stix_packages do single? end
end