object @stix_marking

attributes :controlled_structure,
           :guid,
           :remote_object_type,
           :remote_object_id,
           :remote_object_field,
           :stix_id,
           :id

child :isa_marking_structure => 'isa_marking_structure' do
  extends "isa_marking_structures/show", locals: {associations: locals[:associations]}
end

child :isa_assertion_structure => 'isa_assertion_structure' do
  extends "isa_assertion_structure/show", locals: {associations: locals[:associations]}
end

child :tlp_marking_structure => 'tlp_marking_structure' do
  attributes :id,:stix_id,:color,:guid
end

child :simple_marking_structure => 'simple_marking_structure' do
  attributes :id,:stix_id,:guid,:statement
end

child :ais_consent_marking_structure => 'ais_consent_marking_structure' do
  attributes :id, :consent, :guid, :color, :proprietary
end