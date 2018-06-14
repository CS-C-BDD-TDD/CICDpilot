class Acs2DataMigration < ActiveRecord::Migration

  class AStixMarking < ActiveRecord::Base
    self.table_name = 'stix_markings'
    has_many :a_old_isa_marking_structures, primary_key: :guid, foreign_key: :stix_marking_guid
  end

  # The class for the old 2.0 ISA Marking Structures (the ones being refactored)

  class AOldIsaMarkingStructure < ActiveRecord::Base
    self.table_name = 'old_isa_marking_structures'
  end

  # The class for the revised TLP Marking Structures

  class ATlpStructure < ActiveRecord::Base
    self.table_name = 'tlp_structures'
  end

  # The class for the revised Simple Marking Structures

  class ASimpleStructure < ActiveRecord::Base
    self.table_name = 'simple_structures'
  end

  # The class for the new ACS 2.0 ISA Marking Structures

  class AIsaMarkingStructure < ActiveRecord::Base
    self.table_name = 'isa_marking_structures'
  end

  # The class for the new ACS 2.0 ISA Marking Privileges

  class AIsaAssertionStructure < ActiveRecord::Base
    self.table_name = 'isa_assertion_structures'
  end

  def up
    AStixMarking.reset_column_information
    AIsaMarkingStructure.reset_column_information

    AStixMarking.all.each do |m|
      case m.old_marking_model_type
        when 'TLPMarkingStructureType'
             migrate_tlp(m)
        when 'SimpleMarkingStructureType'
             migrate_simple(m)
        when 'ISAMarkingsAssertionType'
             migrate_isa_assertion(m)
        when 'ISAMarkingsType'
             migrate_isa_structure(m)
        else
          if m.old_marking_model_type.present?
            puts "Skipping unknown structure: #{m.old_marking_model_type}"
          end
      end
    end
  end

  def down
  end

  def migrate_tlp(m)
    ms = ATlpStructure.new(color: m.old_marking_value, guid: SecureRandom.uuid,
           stix_marking_id: m.stix_id)
    ms.stix_id = SecureRandom.stix_id(ms)
    ms.stix_id = ms.stix_id.gsub(/Acs2DataMigration::A/,'')
    ms.save

    m.tlp_structure_id = ms.stix_id
    m.save
  end

  def migrate_simple(m)
    ms = ASimpleStructure.new(statement: m.old_marking_value,
           guid: SecureRandom.uuid, stix_marking_id: m.stix_id)
    ms.stix_id = SecureRandom.stix_id(ms)
    ms.stix_id = ms.stix_id.gsub(/Acs2DataMigration::A/,'')
    ms.save

    m.simple_structure_id = ms.stix_id
    m.save
  end

  def migrate_isa_assertion(m)
    old_ms = m.a_old_isa_marking_structures.first
    if old_ms
      ms = AIsaAssertionStructure.new
      ms.guid = SecureRandom.uuid
      ms.cs_classification = old_ms.cs_classification || 'U'
      ms.cs_countries = old_ms.cs_countries
      ms.cs_cui = old_ms.cs_cui
      ms.cs_entity = old_ms.cs_entity
      ms.cs_formal_determination = old_ms.cs_formal_determination
      ms.cs_orgs = old_ms.cs_orgs
      ms.cs_shargrp = old_ms.cs_shargrp
      ms.is_default_marking = old_ms.is_default_marking
      ms.privilege_default = old_ms.privilege_default
      ms.public_release = old_ms.public_release
      ms.public_released_by = old_ms.public_released_by
      ms.public_released_on = old_ms.public_released_on
      ms.stix_id = SecureRandom.stix_id(ms)
      ms.stix_id = ms.stix_id.gsub(/Acs2DataMigration::A/,'')
      ms.stix_marking_id = m.stix_id
      ms.save

      m.isa_marking_structure_id = ms.stix_id
      m.save
    end
  end

  def migrate_isa_structure(m)
    old_ms = m.a_old_isa_marking_structures.first
    if old_ms
      ms = AIsaMarkingStructure.new
      ms.guid = SecureRandom.uuid
      ms.re_custodian = old_ms.re_custodian
      ms.data_item_created_at = old_ms.re_data_item_created_at
      ms.re_originator = old_ms.re_originator
      ms.stix_id = SecureRandom.stix_id(ms)
      ms.stix_id = ms.stix_id.gsub(/Acs2DataMigration::A/,'')
      ms.stix_marking_id = m.stix_id
      ms.save

      m.isa_marking_structure_id = ms.stix_id
      m.save
    end
  end

end
