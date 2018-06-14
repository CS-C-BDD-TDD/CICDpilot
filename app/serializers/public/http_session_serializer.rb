class Public::HttpSessionSerializer < Serializer
  attributes :cybox_object_id,
             :cybox_hash,
             :user_agent,
             :domain_name,
             :port,
             :refer,
             :pragma
end
