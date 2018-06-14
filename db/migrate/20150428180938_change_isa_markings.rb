class ChangeIsaMarkings < ActiveRecord::Migration

  def change

    create_table :isa_marking_structures do |t|
      t.string   :cs_classification              # CLS
      t.string   :cs_countries, limit: 1000      # CTRY
      t.string   :cs_cui                         # CUI
      t.string   :cs_entity                      # ENTITY
      t.string   :cs_formal_determination        # FD
      t.string   :cs_info_caveat                 # CVT
      t.string   :cs_orgs                        # ORG
      t.string   :cs_shargrp                     # SHARGRP
      t.string   :guid
      t.string   :is_default_marking, null: false, default: false
      t.string   :is_reference, null: false, default: false
      t.string   :marking_model_type
      t.string   :privilege_default, null: false, default: 'deny'
      t.boolean  :public_release, null: false, default: false
      t.string   :public_released_by
      t.datetime :public_released_on
      t.string   :re_custodian                   # CUST
      t.datetime :re_data_item_created_at        # When created
      t.string   :re_originator                  # ORIG
      t.string   :stix_id
      t.string   :stix_marking_guid              # Foreign Key
      t.timestamps
    end

    add_index :isa_marking_structures, :guid
    add_index :isa_marking_structures, :stix_id
    add_index :isa_marking_structures, :stix_marking_guid
  end

end
