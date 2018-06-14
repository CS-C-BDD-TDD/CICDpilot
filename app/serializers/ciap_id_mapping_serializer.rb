class CiapIdMappingSerializer < Serializer
  	attributes :original_id,
               :sanitized_id,
               :created_at,
               :updated_at
end
