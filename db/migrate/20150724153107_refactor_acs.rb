class RefactorAcs < ActiveRecord::Migration

  def up
    up_old_tables
    up_stix_markings
    up_tlp_structures
    up_simple_structures
    up_isa_marking_structures
    up_isa_assertion_structures
    up_isa_privs
  end

  def down
    down_isa_marking_structures
    down_old_tables
    down_stix_markings
    down_tlp_structures
    down_simple_structures
    down_isa_assertion_structures
    down_isa_privs
  end

  # --- OLD TABLES ----------------------------------------------------------

  # Saving the "old" tables to support data migration as needed

  def up_old_tables
    rename_table :isa_markings, :old_isa_markings  # ACS 1.1
    rename_table :isa_marking_structures, :old_isa_marking_structures
  end

  def down_old_tables
    rename_table :old_isa_markings, :isa_markings  # ACS 1.1
    rename_table :old_isa_marking_structures, :isa_marking_structures
  end

  # --- STIX_MARKINGS -------------------------------------------------------

  # Saving the "old" columns to support data migration as needed

  def up_stix_markings
    change_table :stix_markings do |t|
      t.rename :marking_model_name, :old_marking_model_name
      t.rename :marking_model_type, :old_marking_model_type
      t.rename :marking_name,       :old_marking_name
      t.rename :marking_value,      :old_marking_value
      t.column :tlp_structure_id, :string
      t.column :simple_structure_id, :string
      t.column :isa_marking_structure_id, :string
      t.column :isa_assertion_structure_id, :string
    end
  end

  def down_stix_markings
    change_table :stix_markings do |t|
      t.rename :old_marking_model_name, :marking_model_name
      t.rename :old_marking_model_type, :marking_model_type
      t.rename :old_marking_name,       :marking_name
      t.rename :old_marking_value,      :marking_value
      t.remove :tlp_structure_id
      t.remove :simple_structure_id
      t.remove :isa_marking_structure_id
      t.remove :isa_assertion_structure_id
    end
  end

  # --- TLP_STRUCTURES ------------------------------------------------------

  def up_tlp_structures
    create_table :tlp_structures do |t|
      t.string :color, :null => false
      t.string :guid, :null => false
      t.string :stix_id, :null => false
      t.string :stix_marking_id
    end
  end

  def down_tlp_structures
    drop_table :tlp_structures
  end

  # --- SIMPLE_STRUCTURES ---------------------------------------------------

  def up_simple_structures
    create_table :simple_structures do |t|
      t.string :guid, :null => false
      t.text :statement, :null => false
      t.string :stix_id, :null => false
      t.string :stix_marking_id
    end
  end

  def down_simple_structures
    drop_table :simple_structures
  end

  # --- ISA_MARKING_STRUCTURES ----------------------------------------------

  def up_isa_marking_structures
    create_table :isa_marking_structures do |t|
      t.datetime :data_item_created_at
      t.string :guid, :null => false
      t.string :re_custodian, :null => false
      t.string :re_originator
      t.string :stix_id, :null => false
      t.string :stix_marking_id
    end
  end

  def down_isa_marking_structures
    drop_table :isa_marking_structures
  end

  # --- ISA_ASSERTION_STRUCTURES --------------------------------------------

  def up_isa_assertion_structures
    create_table :isa_assertion_structures do |t|
      t.string :cs_classification, :null => false, :default => 'U'
      t.string :cs_countries
      t.string :cs_cui
      t.string :cs_entity
      t.string :cs_formal_determination
      t.string :cs_orgs
      t.string :cs_shargrp
      t.string :guid, :null => false
      t.boolean :is_default_marking, :null => false, :default => false
      t.string :privilege_default, :null => false, :default => 'deny'
      t.boolean :public_release, :null => false, :default => false
      t.string :public_released_by
      t.datetime :public_released_on
      t.string :stix_id, :null => false
      t.string :stix_marking_id
    end
  end

  def down_isa_assertion_structures
    drop_table :isa_assertion_structures
  end

  # --- ISA_PRIVS -----------------------------------------------------------

  def up_isa_privs
    change_table :isa_privs do |t|
      t.rename :isa_marking_structure_guid, :isa_assertion_structure_guid
    end
  end

  def down_isa_privs
    change_table :isa_privs do |t|
      t.rename :isa_assertion_structure_guid, :isa_marking_structure_guid
    end
  end

end
