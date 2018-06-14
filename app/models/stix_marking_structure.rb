class StixMarkingStructure < ActiveRecord::Base
  belongs_to :stix_marking,
             primary_key: :stix_id,
             foreign_key: :stix_marking_id

  belongs_to :stix_structure,
             primary_key: :stix_id,
             polymorphic: true

  belongs_to :isa_assertion_structure,
             primary_key: :stix_id,
             foreign_key: :stix_structure_id,
             foreign_type: :stix_structure_type

  belongs_to :isa_marking_structure,
             primary_key: :stix_id,
             foreign_key: :stix_structure_id,
             foreign_type: :stix_structure_type

  belongs_to :simple_structure,
             primary_key: :stix_id,
             foreign_key: :stix_structure_id,
             foreign_type: :stix_structure_type

  belongs_to :tlp_structure,
             primary_key: :stix_id,
             foreign_key: :stix_structure_id,
             foreign_type: :stix_structure_type

  belongs_to :ais_consent_marking_structure,
             primary_key: :stix_id,
             foreign_key: :stix_structure_id,
             foreign_type: :stix_structure_type
end
