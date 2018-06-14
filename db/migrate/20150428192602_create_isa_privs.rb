class CreateIsaPrivs < ActiveRecord::Migration
  def change
    create_table :isa_privs do |t|
      t.string   :action                          # Privilege
      t.string   :effect, null: false, default: 'deny' 
      t.string   :guid                            # Unique ID
      t.string   :isa_marking_structure_guid      # Foreign Key
      t.string   :scope_countries, limit: 1000    # Restrict by CTRY
      t.string   :scope_entity                    # Restrict by ENTITY
      t.boolean  :scope_is_all, null: false, default: true  # For ALL?
      t.string   :scope_orgs                      # Restrict by ORG
      t.string   :scope_shargrp                   # Restrict by SHARGRP
    end

    add_index :isa_privs, :guid
    add_index :isa_privs, :isa_marking_structure_guid
  end
end
