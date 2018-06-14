class AddConditionColumnDefaults < ActiveRecord::Migration
  class MUri < ActiveRecord::Base
    self.table_name = :cybox_uris
  end
  class MLink < ActiveRecord::Base
    self.table_name = :cybox_links
  end
  class MRegistry < ActiveRecord::Base
    self.table_name = :cybox_win_registry_keys
  end
  class MAddress < ActiveRecord::Base
    self.table_name = :cybox_addresses
  end
  class MHttpSession < ActiveRecord::Base
    self.table_name = :cybox_http_sessions
  end
  class MRegistryValue < ActiveRecord::Base
    self.table_name = :cybox_win_registry_values
  end
  class MEmailMessage < ActiveRecord::Base
    self.table_name = :cybox_email_messages
  end
  class MDomain < ActiveRecord::Base
    self.table_name = :cybox_domains
  end
  class MHostname < ActiveRecord::Base
    self.table_name = :cybox_hostnames
  end
  class MCyboxFile < ActiveRecord::Base
    self.table_name = :cybox_files
  end

  def up
  	change_column_default :cybox_uris, :uri_condition, 'Equals'
  	change_column_default :cybox_links, :label_condition, 'Equals'
  	change_column_default :cybox_win_registry_keys, :hive_condition, 'Equals'
  	change_column_default :cybox_addresses, :address_condition, 'Equals'
  	change_column_default :cybox_http_sessions, :user_agent_condition, 'Equals'
  	change_column_default :cybox_win_registry_values, :data_condition, 'Equals'
  	change_column_default :cybox_email_messages, :subject_condition, 'Equals'
    change_column_default :cybox_domains, :name_condition, 'Equals'

    MUri.where(uri_condition: nil).update_all(uri_condition: 'Equals')
    MLink.where(label_condition: nil).update_all(label_condition: 'Equals')
    MRegistry.where(hive_condition: nil).update_all(hive_condition: 'Equals')
    MAddress.where(address_condition: nil).update_all(address_condition: 'Equals')
    MHttpSession.where(user_agent_condition: nil).update_all(user_agent_condition: 'Equals')
    MRegistryValue.where(data_condition: nil).update_all(data_condition: 'Equals')
    MEmailMessage.where(subject_condition: nil).update_all(subject_condition: 'Equals')
    MDomain.where(name_condition: nil).update_all(name_condition: 'Equals')
    MHostname.where(hostname_condition: nil).update_all(hostname_condition: 'Equals')
    MCyboxFile.where(file_name_condition: nil).update_all(file_name_condition: 'Equals')
    MCyboxFile.where(file_path_condition: nil).update_all(file_path_condition: 'Equals')
    MCyboxFile.where(size_in_bytes_condition: nil).update_all(size_in_bytes_condition: 'Equals')
  end

  def down
  	change_column_default :cybox_uris, :uri_condition, nil
  	change_column_default :cybox_links, :label_condition, nil
  	change_column_default :cybox_win_registry_keys, :hive_condition, nil
  	change_column_default :cybox_addresses, :address_condition, nil
  	change_column_default :cybox_http_sessions, :user_agent_condition, nil
  	change_column_default :cybox_win_registry_values, :data_condition, nil
  	change_column_default :cybox_email_messages, :subject_condition, nil
    change_column_default :cybox_domains, :name_condition, nil
  end
end
