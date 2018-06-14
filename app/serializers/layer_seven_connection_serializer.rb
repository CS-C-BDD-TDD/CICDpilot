class LayerSevenConnectionSerializer < Serializer
  	attributes :guid,
  			       :cybox_hash,
  			       :portion_marking,
  			       :http_session_id,
  			       :dns_query_cache,
  			       :is_reference,
  			       :read_only,
  			       :created_at,
  			       :updated_at

    associate :http_session do single? end

    node :http_session_display_name do |lsc|
      lsc.http_session.present? ? lsc.http_session.display_name : ''
    end
    
    associate :dns_queries do single? end

    associate :network_connections do single? end
    associate :stix_packages do single? end
end
