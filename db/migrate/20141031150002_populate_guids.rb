class PopulateGuids < ActiveRecord::Migration
  class MCyboxAddresses < ActiveRecord::Base; self.table_name = 'cybox_addresses'; end
  class MCyboxDomains < ActiveRecord::Base; self.table_name = 'cybox_domains'; end
  class MCyboxEmailMessages < ActiveRecord::Base; self.table_name = 'cybox_email_messages'; end
  class MCyboxFileHashes < ActiveRecord::Base; self.table_name = 'cybox_file_hashes'; end
  class MCyboxFiles < ActiveRecord::Base; self.table_name = 'cybox_files'; end
  class MCyboxObservables < ActiveRecord::Base; self.table_name = 'cybox_observables'; end
  class MCyboxUris < ActiveRecord::Base; self.table_name = 'cybox_uris'; end
  class MGroups < ActiveRecord::Base; self.table_name = 'groups'; end
  class MGroupsPermissions < ActiveRecord::Base; self.table_name = 'groups_permissions'; end
  class MOriginalInput < ActiveRecord::Base; self.table_name = 'original_input'; end
  class MPermissions < ActiveRecord::Base; self.table_name = 'permissions'; end
  class MStixIndicators < ActiveRecord::Base; self.table_name = 'stix_indicators'; end
  class MStixIndicatorsPackages < ActiveRecord::Base; self.table_name = 'stix_indicators_packages'; end
  class MStixKillChains < ActiveRecord::Base; self.table_name = 'stix_kill_chains'; end
  class MStixPackages < ActiveRecord::Base; self.table_name = 'stix_packages'; end
  class MStixSightings < ActiveRecord::Base; self.table_name = 'stix_sightings'; end
  class MTagAssignments < ActiveRecord::Base; self.table_name = 'tag_assignments'; end
  class MTags < ActiveRecord::Base; self.table_name = 'tags'; end
  class MUploadedFiles < ActiveRecord::Base; self.table_name = 'uploaded_files'; end
  class MUsers < ActiveRecord::Base; self.table_name = 'users'; end
  class MUsersGroups < ActiveRecord::Base; self.table_name = 'users_groups'; end

  def up
    add_guids_to_table(MCyboxAddresses)
    add_guids_to_table(MCyboxDomains)
    add_guids_to_table(MCyboxEmailMessages)
    add_guids_to_table(MCyboxFileHashes)
    add_guids_to_table(MCyboxFiles)
    add_guids_to_table(MCyboxObservables)
    add_guids_to_table(MCyboxUris)
    add_guids_to_table(MGroups)
    add_guids_to_table(MGroupsPermissions)
    add_guids_to_table(MOriginalInput)
    add_guids_to_table(MPermissions)
    add_guids_to_table(MStixIndicators)
    add_guids_to_table(MStixIndicatorsPackages)
    add_guids_to_table(MStixKillChains)
    add_guids_to_table(MStixPackages)
    add_guids_to_table(MStixSightings)
    add_guids_to_table(MTagAssignments)
    add_guids_to_table(MTags)
    add_guids_to_table(MUploadedFiles)
    add_guids_to_table(MUsers)
    add_guids_to_table(MUsersGroups)
  end

  def add_guids_to_table(klass)
    klass.all.each do |k|
      if k.guid.blank?
        k.guid = SecureRandom.uuid
        k.save
      end
    end
  end
end
