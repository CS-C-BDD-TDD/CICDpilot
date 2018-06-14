class CreateStixPackages < ActiveRecord::Migration
  def change
    create_table :stix_packages do |t|
      t.datetime :created_at
      t.text :description
      t.datetime :info_src_produced_time
      t.boolean :is_reference, :default => false
      t.string :package_intent
      t.text :short_description
      t.string :stix_id
      t.datetime :stix_timestamp
      t.string :title
      t.datetime :updated_at
      t.integer :uploaded_file_id    # Application-specific column
      t.string :username         # Keeping for now, but may change later
      t.string :created_by_user_guid
      t.string :updated_by_user_guid
      t.string :created_by_organization_guid
      t.string :updated_by_organization_guid
      t.string :r5_container_type
      t.integer :r5_container_id
    end

    add_index :stix_packages, :stix_id
  end
end
