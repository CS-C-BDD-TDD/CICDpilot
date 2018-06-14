class HumanReviewFieldSerializer < Serializer
  attributes :id,
             :is_changed,
             :object_field,
             :object_field_revised,
             :object_field_original,
             :object_uid,
             :object_type,
             :has_pii

end