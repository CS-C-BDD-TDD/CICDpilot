class UpdateAssociationsToUseGuids < ActiveRecord::Migration
  class MAcsSetsOrganizations < ActiveRecord::Base
    self.table_name = :acs_sets_organizations

    belongs_to :acs_set, primary_key: :id
    belongs_to :organization, primary_key: :id
  end
  class MCourseOfActions < ActiveRecord::Base
    self.table_name = :course_of_actions

    belongs_to :acs_set, primary_key: :id
  end
  class MEmailLinks < ActiveRecord::Base
    self.table_name = :email_links

    belongs_to :email_message, primary_key: :id
    belongs_to :link, primary_key: :id
  end
  class MEmailUris < ActiveRecord::Base
    self.table_name = :email_uris

    belongs_to :email_message, primary_key: :id
    belongs_to :uri, primary_key: :id
  end
  class MErrorMessages < ActiveRecord::Base
    self.table_name = :error_messages

    belongs_to :uploaded_file, primary_key: :id, foreign_key: :source_id
  end
  class MExploitTargets < ActiveRecord::Base
    self.table_name = :exploit_targets

    belongs_to :acs_set, primary_key: :id
  end
  class MOriginalInput < ActiveRecord::Base
    self.table_name = :original_input

    belongs_to :uploaded_file, primary_key: :id
  end
  class MStixIndicators < ActiveRecord::Base
    self.table_name = :stix_indicators

    belongs_to :acs_set, primary_key: :id
  end
  class MStixPackages < ActiveRecord::Base
    self.table_name = :stix_packages

    belongs_to :uploaded_file, primary_key: :id
    belongs_to :acs_set, primary_key: :id
  end
  class MThreatActors < ActiveRecord::Base
    self.table_name = :threat_actors

    belongs_to :acs_set, primary_key: :id
  end
  class MTtps < ActiveRecord::Base
    self.table_name = :ttps

    belongs_to :acs_set, primary_key: :id
  end

  def up
Rails.logger.level=5
    unless ActiveRecord::Base.connection.column_exists?(:acs_sets, :acs_sets_org_guid)
      add_column :acs_sets, :acs_sets_org_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :organization_guid)
      add_column :acs_sets_organizations, :organization_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:acs_sets_organizations, :acs_set_guid)
      add_column :acs_sets_organizations, :acs_set_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:course_of_actions, :acs_set_guid)
      add_column :course_of_actions, :acs_set_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:cybox_observables, :parent_guid)
      add_column :cybox_observables, :parent_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_links, :email_message_guid)
      add_column :email_links, :email_message_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_links, :link_guid)
      add_column :email_links, :link_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_uris, :email_message_guid)
      add_column :email_uris, :email_message_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:email_uris, :uri_guid)
      add_column :email_uris, :uri_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:error_messages, :source_guid)
      add_column :error_messages, :source_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:exploit_targets, :acs_set_guid)
      add_column :exploit_targets, :acs_set_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:organizations, :acs_sets_org_guid)
      add_column :organizations, :acs_sets_org_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:original_input, :uploaded_file_guid)
      add_column :original_input, :uploaded_file_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_indicators, :parent_guid)
      add_column :stix_indicators, :parent_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_indicators, :acs_set_guid)
      add_column :stix_indicators, :acs_set_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_packages, :uploaded_file_guid)
      add_column :stix_packages, :uploaded_file_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:stix_packages, :acs_set_guid)
      add_column :stix_packages, :acs_set_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:threat_actors, :acs_set_guid)
      add_column :threat_actors, :acs_set_guid, :string
    end
    unless ActiveRecord::Base.connection.column_exists?(:ttps, :acs_set_guid)
      add_column :ttps, :acs_set_guid, :string
    end

    batch_size=10000

    total_groups = (MAcsSetsOrganizations.count-1)/batch_size
    MAcsSetsOrganizations.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "ACS Sets Organizations - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |aso|
          aso.update_column(:organization_guid, aso.organization.guid) if aso.organization.present?
          aso.update_column(:acs_set_guid, aso.acs_set.guid) if aso.acs_set.present?
        end
      end
    end

    total_groups = (MCourseOfActions.count-1)/batch_size
    MCourseOfActions.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Courses of Action - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |coa|
          coa.update_column(:acs_set_guid, coa.acs_set.guid) if coa.acs_set.present?
        end
      end
    end

    total_groups = (MEmailLinks.count-1)/batch_size
    MEmailLinks.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Email Links - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |el|
          el.update_column(:email_message_guid, el.email_message.guid) if el.email_message.present?
          el.update_column(:link_guid, el.link.guid) if el.link.present?
        end
      end
    end

    total_groups = (MEmailUris.count-1)/batch_size
    MEmailUris.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Email Uris - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |eu|
          eu.update_column(:email_message_guid, eu.email_message.guid) if eu.email_message.present?
          eu.update_column(:uri_guid, eu.link.guid) if eu.link.present?
        end
      end
    end

    total_groups = (MErrorMessages.count-1)/batch_size
    MErrorMessages.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Error Messages - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |em|
          em.update_column(:source_guid, em.uploaded_file.guid) if em.uploaded_file.present?
        end
      end
    end

    total_groups = (MExploitTargets.count-1)/batch_size
    MExploitTargets.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Exploit Targets - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |et|
          et.update_column(:acs_set_guid, et.acs_set.guid) if et.acs_set.present?
        end
      end
    end

    total_groups = (MOriginalInput.count-1)/batch_size
    MOriginalInput.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Original Input - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |oi|
          oi.update_column(:uploaded_file_guid, oi.uploaded_file.guid) if oi.uploaded_file.present?
        end
      end
    end

    total_groups = (MStixIndicators.count-1)/batch_size
    MStixIndicators.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "STIX Indicators - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |si|
          si.update_column(:acs_set_guid, si.acs_set.guid) if si.acs_set.present?
        end
      end
    end

    total_groups = (MStixPackages.count-1)/batch_size
    MStixPackages.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "STIX Packages - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |sp|
          sp.update_column(:uploaded_file_guid, sp.uploaded_file.guid) if sp.uploaded_file.present?
          sp.update_column(:acs_set_guid, sp.acs_set.guid) if sp.acs_set.present?
        end
      end
    end

    total_groups = (MThreatActors.count-1)/batch_size
    MThreatActors.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "Threat Actors - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |ta|
          ta.update_column(:acs_set_guid, ta.acs_set.guid) if ta.acs_set.present?
        end
      end
    end

    total_groups = (MTtps.count-1)/batch_size
    MTtps.find_in_batches(batch_size: batch_size).with_index do |group,batch|
      puts "TTPs - Processing group ##{batch+1} of #{total_groups+1}"
      ActiveRecord::Base.transaction do
        group.each do |t|
          t.update_column(:acs_set_guid, t.acs_set.guid) if t.acs_set.present?
        end
      end
    end

    remove_index :cybox_observables, :parent_id
    remove_index :error_messages, :source_id
    remove_index :original_input, :uploaded_file_id

    rename_column :acs_sets, :acs_sets_org_id, :old_acs_sets_org_id
    rename_column :acs_sets_organizations, :organization_id, :old_organization_id
    rename_column :acs_sets_organizations, :acs_set_id, :old_acs_set_id
    rename_column :course_of_actions, :acs_set_id, :old_acs_set_id
    rename_column :cybox_observables, :parent_id, :old_parent_id
    rename_column :email_links, :email_message_id, :old_email_message_id
    rename_column :email_links, :link_id, :old_link_id
    rename_column :email_uris, :email_message_id, :old_email_message_id
    rename_column :email_uris, :uri_id, :old_uri_id
    rename_column :error_messages, :source_id, :old_source_id
    rename_column :exploit_targets, :acs_set_id, :old_acs_set_id
    rename_column :organizations, :acs_sets_org_id, :old_acs_sets_org_id
    rename_column :original_input, :uploaded_file_id, :old_uploaded_file_id
    rename_column :stix_indicators, :parent_id, :old_parent_id
    rename_column :stix_indicators, :acs_set_id, :old_acs_set_id
    rename_column :stix_packages, :uploaded_file_id, :old_uploaded_file_id
    rename_column :stix_packages, :acs_set_id, :old_acs_set_id
    rename_column :threat_actors, :acs_set_id, :old_acs_set_id
    rename_column :ttps, :acs_set_id, :old_acs_set_id

    rename_column :acs_sets, :acs_sets_org_guid, :acs_sets_org_id
    rename_column :acs_sets_organizations, :organization_guid, :organization_id
    rename_column :acs_sets_organizations, :acs_set_guid, :acs_set_id
    rename_column :course_of_actions, :acs_set_guid, :acs_set_id
    rename_column :cybox_observables, :parent_guid, :parent_id
    rename_column :email_links, :email_message_guid, :email_message_id
    rename_column :email_links, :link_guid, :link_id
    rename_column :email_uris, :email_message_guid, :email_message_id
    rename_column :email_uris, :uri_guid, :uri_id
    rename_column :error_messages, :source_guid, :source_id
    rename_column :exploit_targets, :acs_set_guid, :acs_set_id
    rename_column :organizations, :acs_sets_org_guid, :acs_sets_org_id
    rename_column :original_input, :uploaded_file_guid, :uploaded_file_id
    rename_column :stix_indicators, :parent_guid, :parent_id
    rename_column :stix_indicators, :acs_set_guid, :acs_set_id
    rename_column :stix_packages, :uploaded_file_guid, :uploaded_file_id
    rename_column :stix_packages, :acs_set_guid, :acs_set_id
    rename_column :threat_actors, :acs_set_guid, :acs_set_id
    rename_column :ttps, :acs_set_guid, :acs_set_id

    add_index :cybox_observables, :parent_id
    add_index :error_messages, :source_id
    add_index :original_input, :uploaded_file_id
  end

  def down
    remove_index :cybox_observables, :parent_id
    remove_index :error_messages, :source_id
    remove_index :original_input, :uploaded_file_id

    remove_column :acs_sets, :acs_sets_org_id
    remove_column :acs_sets_organizations, :organization_id
    remove_column :acs_sets_organizations, :acs_set_id
    remove_column :course_of_actions, :acs_set_id
    remove_column :cybox_observables, :parent_id
    remove_column :email_links, :email_message_id
    remove_column :email_links, :link_id
    remove_column :email_uris, :email_message_id
    remove_column :email_uris, :uri_id
    remove_column :error_messages, :source_id
    remove_column :exploit_targets, :acs_set_id
    remove_column :organizations, :acs_sets_org_id
    remove_column :original_input, :uploaded_file_id
    remove_column :stix_indicators, :parent_id
    remove_column :stix_indicators, :acs_set_id
    remove_column :stix_packages, :uploaded_file_id
    remove_column :stix_packages, :acs_set_id
    remove_column :threat_actors, :acs_set_id
    remove_column :ttps, :acs_set_id

    rename_column :acs_sets, :old_acs_sets_org_id, :acs_sets_org_id
    rename_column :acs_sets_organizations, :old_organization_id, :organization_id
    rename_column :acs_sets_organizations, :old_acs_set_id, :acs_set_id
    rename_column :course_of_actions, :old_acs_set_id, :acs_set_id
    rename_column :cybox_observables, :old_parent_id, :parent_id
    rename_column :email_links, :old_email_message_id, :email_message_id
    rename_column :email_links, :old_link_id, :link_id
    rename_column :email_uris, :old_email_message_id, :email_message_id
    rename_column :email_uris, :old_uri_id, :uri_id
    rename_column :error_messages, :old_source_id, :source_id
    rename_column :exploit_targets, :old_acs_set_id, :acs_set_id
    rename_column :organizations, :old_acs_sets_org_id, :acs_sets_org_id
    rename_column :original_input, :old_uploaded_file_id, :uploaded_file_id
    rename_column :stix_indicators, :old_parent_id, :parent_id
    rename_column :stix_indicators, :old_acs_set_id, :acs_set_id
    rename_column :stix_packages, :old_uploaded_file_id, :uploaded_file_id
    rename_column :stix_packages, :old_acs_set_id, :acs_set_id
    rename_column :threat_actors, :old_acs_set_id, :acs_set_id
    rename_column :ttps, :old_acs_set_id, :acs_set_id

    add_index :cybox_observables, :parent_id
    add_index :error_messages, :source_id
    add_index :original_input, :uploaded_file_id
  end
end
