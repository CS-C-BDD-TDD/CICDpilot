class AddGuids < ActiveRecord::Migration

  class MigrationTag < ActiveRecord::Base
    self.table_name = 'tags'
  end

  def change
    add_column :cybox_addresses, :guid, :string
    add_index :cybox_addresses, :guid
    add_column :cybox_domains, :guid, :string
    add_index :cybox_domains, :guid
    add_column :cybox_email_messages, :guid, :string
    add_index :cybox_email_messages, :guid
    add_column :cybox_file_hashes, :guid, :string
    add_index :cybox_file_hashes, :guid
    add_column :cybox_files, :guid, :string
    add_index :cybox_files, :guid
    add_column :cybox_observables, :guid, :string
    add_index :cybox_observables, :guid
    add_column :cybox_uris, :guid, :string
    add_index :cybox_uris, :guid
    add_column :groups, :guid, :string
    add_index :groups, :guid
    add_column :groups_permissions, :guid, :string
    add_index :groups_permissions, :guid
    add_column :original_input, :guid, :string
    add_index :original_input, :guid
    add_column :permissions, :guid, :string
    add_index :permissions, :guid
    add_column :stix_indicators, :guid, :string
    add_index :stix_indicators, :guid
    add_column :stix_indicators_packages, :guid, :string
    add_index :stix_indicators_packages, :guid
    add_column :stix_kill_chains, :guid, :string
    add_index :stix_kill_chains, :guid
    add_column :stix_packages, :guid, :string
    add_index :stix_packages, :guid
    add_column :stix_sightings, :guid, :string
    add_index :stix_sightings, :guid
    add_column :tag_assignments, :guid, :string
    add_index :tag_assignments, :guid
    add_column :tags, :guid, :string
    add_index :tags, :guid
    add_column :uploaded_files, :guid, :string
    add_index :uploaded_files, :guid
    add_column :users, :guid, :string
    add_index :users, :guid
    add_column :users_groups, :guid, :string
    add_index :users_groups, :guid

    # hard coded guid to match on all systems
    MigrationTag.find_by_name('excluded-from-e1').update_column('guid', '6acc3b27-161e-4284-b785-734b9ea9c49c')
  end
end
