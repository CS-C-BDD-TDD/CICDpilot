class AddGuidAndUpdatedAtToModels < ActiveRecord::Migration
  class MAcsSetsOrganizations < ActiveRecord::Base;self.table_name = :acs_sets_organizations; end
  class MEmailFiles < ActiveRecord::Base;self.table_name = :email_files; end
  class MEmailLinks < ActiveRecord::Base;self.table_name = :email_links; end
  class MEmailUris < ActiveRecord::Base;self.table_name = :email_uris; end
  class MErrorMessages < ActiveRecord::Base;self.table_name = :error_messages; end
  class MIsaEntityCaches < ActiveRecord::Base;self.table_name = :isa_entity_caches; end

  def up
    # Add GUID to tables that are missing them, where needed
    unless ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :guid)
      add_column :acs_sets_organizations, :guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_files, :guid)
      add_column :email_files, :guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_links, :guid)
      add_column :email_links, :guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_uris, :guid)
      add_column :email_uris, :guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:error_messages, :guid)
      add_column :error_messages, :guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_entity_caches, :guid)
      add_column :isa_entity_caches, :guid, :string
    end

    unless ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :updated_at)
      add_column :acs_sets_organizations, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:ais_consent_marking_structures, :updated_at)
      add_column :ais_consent_marking_structures, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:cybox_win_registry_values, :updated_at)
      add_column :cybox_win_registry_values, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_files, :updated_at)
      add_column :email_files, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_links, :updated_at)
      add_column :email_links, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_uris, :updated_at)
      add_column :email_uris, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:further_sharings, :updated_at)
      add_column :further_sharings, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_assertion_structures, :updated_at)
      add_column :isa_assertion_structures, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_marking_structures, :updated_at)
      add_column :isa_marking_structures, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:isa_privs, :updated_at)
      add_column :isa_privs, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:simple_structures, :updated_at)
      add_column :simple_structures, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_sightings, :updated_at)
      add_column :stix_sightings, :updated_at, :timestamp
    end
    unless ActiveRecord::Base.connection.column_exists?(:tlp_structures, :updated_at)
      add_column :tlp_structures, :updated_at, :timestamp
    end

    batch_size=10000

    total_groups = (MAcsSetsOrganizations.where('guid is null').count-1)/batch_size
    MAcsSetsOrganizations.where('guid is null').find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "ACS Sets Organizations - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |aso|
          aso.update_column(:guid,SecureRandom.uuid)
        end
      end
    end

    total_groups = (MEmailFiles.where('guid is null').count-1)/batch_size
    MEmailFiles.where('guid is null').find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Email Files - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |ef|
          ef.update_column(:guid,SecureRandom.uuid)
        end
      end
    end

    total_groups = (MEmailLinks.where('guid is null').count-1)/batch_size
    MEmailLinks.where('guid is null').find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Email Links - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |el|
          el.update_column(:guid,SecureRandom.uuid)
        end
      end
    end

    total_groups = (MEmailUris.where('guid is null').count-1)/batch_size
    MEmailUris.where('guid is null').find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Email Uris - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |eu|
          eu.update_column(:guid,SecureRandom.uuid)
        end
      end
    end

    total_groups = (MErrorMessages.where('guid is null').count-1)/batch_size
    MErrorMessages.where('guid is null').find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Error Messages - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |em|
          em.update_column(:guid,SecureRandom.uuid)
        end
      end
    end

    total_groups = (MIsaEntityCaches.where('guid is null').count-1)/batch_size
    MIsaEntityCaches.where('guid is null').find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "ISA Entity Caches - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |iec|
          iec.update_column(:guid,SecureRandom.uuid)
        end
      end
    end
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :guid)
      remove_column :acs_sets_organizations, :guid, :string
    end
    if ActiveRecord::Base.connection.column_exists?(:email_files, :guid)
      remove_column :email_files, :guid, :string
    end
    if ActiveRecord::Base.connection.column_exists?(:email_links, :guid)
      remove_column :email_links, :guid, :string
    end
    if ActiveRecord::Base.connection.column_exists?(:email_uris, :guid)
      remove_column :email_uris, :guid, :string
    end
    if ActiveRecord::Base.connection.column_exists?(:error_messages, :guid)
      remove_column :error_messages, :guid, :string
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_entity_caches, :guid)
      remove_column :isa_entity_caches, :guid, :string
    end

    if ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :updated_at)
      remove_column :acs_sets_organizations, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:ais_consent_marking_structures, :updated_at)
      remove_column :ais_consent_marking_structures, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:cybox_win_registry_values, :updated_at)
      remove_column :cybox_win_registry_values, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:email_files, :updated_at)
      remove_column :email_files, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:email_links, :updated_at)
      remove_column :email_links, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:email_uris, :updated_at)
      remove_column :email_uris, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:further_sharings, :updated_at)
      remove_column :further_sharings, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_assertion_structures, :updated_at)
      remove_column :isa_assertion_structures, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_marking_structures, :updated_at)
      remove_column :isa_marking_structures, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:isa_privs, :updated_at)
      remove_column :isa_privs, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:simple_structures, :updated_at)
      remove_column :simple_structures, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:stix_sightings, :updated_at)
      remove_column :stix_sightings, :updated_at
    end
    if ActiveRecord::Base.connection.column_exists?(:tlp_structures, :updated_at)
      remove_column :tlp_structures, :updated_at
    end

  end
end
