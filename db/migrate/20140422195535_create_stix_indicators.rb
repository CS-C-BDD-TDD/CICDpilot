class CreateStixIndicators < ActiveRecord::Migration
  def change
    create_table :stix_indicators do |t|
      t.string :composite_operator
      t.datetime :created_at
      t.text :description
      t.string :indicator_type
      t.string :indicator_type_vocab_name
      t.string :indicator_type_vocab_ref
      t.boolean :is_composite, :default => false
      t.boolean :is_negated, :default => false
      t.boolean :is_imported, :default => false
      t.boolean :is_reference, :default => false
      t.integer :parent_id
      t.integer :resp_entity_stix_ident_id
      t.string :stix_id
      t.string :dms_label
      t.datetime :stix_timestamp
      t.string :title
      t.datetime :updated_at
      t.string :downgrade_request_id
      t.string :created_by_user_guid
      t.string :updated_by_user_guid
      t.string :created_by_organization_guid
      t.string :updated_by_organization_guid
      t.timestamps
    end

    add_index :stix_indicators, :stix_id
  end
end
