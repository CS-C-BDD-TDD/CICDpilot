class CreateIsaEntityCaches < ActiveRecord::Migration
  def change
    create_table :isa_entity_caches do |t|
      t.string   :admin_org, :null => false, :default => 'USA.DHS.US-CERT'
      t.boolean  :ato_status, :null => false, :default => true
      t.string   :clearance, :null => false, :default => 'U'
      t.string   :country, :null => false, :default => 'USA'
      t.string   :cs_cui
      t.string   :cs_shargrp
      t.string   :distinguished_name
      t.string   :duty_org, :null => false, :default => 'USA.DHS.US-CERT'
      t.string   :entity_class, :null => false, :default => 'PE'  # PE or NPE
      t.string   :entity_type, :null => false, :default => 'GOV'
      t.string   :life_cycle_status, :null => false, :default => 'PROD'
      t.string   :user_guid, :null => false
      t.timestamps
    end
  end
end
