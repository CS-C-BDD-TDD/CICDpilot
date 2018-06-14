class CreateTtpAndAttackPatternsTables < ActiveRecord::Migration
  def up

    if !ActiveRecord::Base.connection.table_exists?(:ttps)
      create_table :ttps do |t|
        t.string :stix_id
        t.string :portion_marking
        t.timestamps
        t.string :guid
        t.string :created_by_user_guid
        t.string :updated_by_user_guid
        t.string :created_by_organization_guid
        t.string :updated_by_organization_guid
        t.integer :acs_set_id
        t.datetime :stix_timestamp
        t.boolean :read_only, :default => false
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:ttps, :guid)
      add_index :ttps, :guid
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:ttps, :stix_id)
      add_index :ttps, :stix_id
    end

    if !ActiveRecord::Base.connection.table_exists?(:attack_patterns)
      create_table :attack_patterns do |t|
        t.string :stix_id
        t.string :title
        t.string :title_c
        t.text   :description
        t.string :description_c
        t.string :description_normalized
        t.string :capec_id
        t.string :capec_id_c
        t.string :portion_marking
        t.timestamps
        t.string :guid
        t.string :created_by_user_guid
        t.string :updated_by_user_guid
        t.string :created_by_organization_guid
        t.string :updated_by_organization_guid
        t.datetime :stix_timestamp
        t.boolean :read_only, :default => false
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:attack_patterns, :stix_id)
      add_index :attack_patterns, :stix_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:attack_patterns, :guid)
      add_index :attack_patterns, :guid
    end

    if !ActiveRecord::Base.connection.index_exists?(:attack_patterns, :capec_id)
      add_index :attack_patterns, :capec_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:attack_patterns, :title)
      add_index :attack_patterns, :title
    end

    if !ActiveRecord::Base.connection.index_exists?(:attack_patterns, :description_normalized)
      add_index :attack_patterns, :description_normalized
    end

    if !ActiveRecord::Base.connection.table_exists?(:ttp_attack_patterns)
      create_table :ttp_attack_patterns do |t|
        t.string :stix_ttp_id
        t.string :stix_attack_pattern_id
        t.timestamps
        t.string :guid
        t.string :user_guid
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:ttp_attack_patterns, :stix_ttp_id)
      add_index :ttp_attack_patterns, :stix_ttp_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:ttp_attack_patterns, :stix_attack_pattern_id)
      add_index :ttp_attack_patterns, :stix_attack_pattern_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:ttp_attack_patterns, :guid)
      add_index :ttp_attack_patterns, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:ttp_packages)
      create_table :ttp_packages do |t|
        t.string :stix_ttp_id
        t.string :stix_package_id
        t.timestamps
        t.string :guid
        t.string :user_guid
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:ttp_packages, :stix_ttp_id)
      add_index :ttp_packages, :stix_ttp_id
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:ttp_packages, :stix_package_id)
      add_index :ttp_packages, :stix_package_id
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:ttp_packages, :guid)
      add_index :ttp_packages, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:ttp_exploit_targets)
      create_table :ttp_exploit_targets do |t|
        t.string :stix_ttp_id
        t.string :stix_exploit_target_id
        t.timestamps
        t.string :guid
        t.string :user_guid
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:ttp_exploit_targets, :stix_ttp_id)
      add_index :ttp_exploit_targets, :stix_ttp_id
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:ttp_exploit_targets, :stix_exploit_target_id)
      add_index :ttp_exploit_targets, :stix_exploit_target_id
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:ttp_exploit_targets, :guid)
      add_index :ttp_exploit_targets, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:indicator_ttps)
      create_table :indicator_ttps do |t|
        t.string :stix_ttp_id
        t.string :stix_indicator_id
        t.timestamps
        t.string :guid
        t.string :user_guid
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:indicator_ttps, :stix_ttp_id)
      add_index :indicator_ttps, :stix_ttp_id
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:indicator_ttps, :stix_indicator_id)
      add_index :indicator_ttps, :stix_indicator_id
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:indicator_ttps, :guid)
      add_index :indicator_ttps, :guid
    end
    
  end

  def down
    remove_index :ttps, :guid
    remove_index :ttps, :stix_id
    remove_index :attack_patterns, :stix_id
    remove_index :attack_patterns, :guid
    remove_index :ttp_attack_patterns, :stix_ttp_id
    remove_index :ttp_attack_patterns, :stix_attack_pattern_id
    remove_index :ttp_attack_patterns, :guid
    remove_index :ttp_packages, :stix_ttp_id
    remove_index :ttp_packages, :stix_package_id
    remove_index :ttp_packages, :guid
    remove_index :ttp_exploit_targets, :stix_ttp_id
    remove_index :ttp_exploit_targets, :stix_exploit_target_id
    remove_index :ttp_exploit_targets, :guid
    remove_index :indicator_ttps, :stix_ttp_id
    remove_index :indicator_ttps, :stix_indicator_id
    remove_index :indicator_ttps, :guid

    drop_table :ttps
    drop_table :attack_patterns
    drop_table :ttp_attack_patterns
    drop_table :ttp_packages
    drop_table :ttp_exploit_targets
    drop_table :indicator_ttps
  end

end
