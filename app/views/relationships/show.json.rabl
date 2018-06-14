object @relationship

attributes :relationship_type,
           :stix_information_source_id,
           :created_at,
           :updated_at,
           :guid

child :confidences => 'confidences' do
  extends "confidences/index"
end

node :audits do |relationship|
  partial "audits/index", object: relationship.remote_src_object.audits
end