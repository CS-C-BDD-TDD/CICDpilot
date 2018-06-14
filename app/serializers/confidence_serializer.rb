class ConfidenceSerializer < Serializer
  attributes :value,
             :is_official,
             :description,
           	 :source,
             :stix_timestamp,
             :created_at
end