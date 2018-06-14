class CreateCourseOfActionsTables < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:course_of_actions)
      create_table :course_of_actions do |t|
        t.string :title
        t.string :title_c
        t.text   :description
        t.string :description_c
        t.string :stix_id
        t.string :portion_marking
        t.datetime :stix_timestamp
        t.timestamps
        t.string :guid
        t.string :created_by_user_guid
        t.string :updated_by_user_guid
        t.string :created_by_organization_guid
        t.string :updated_by_organization_guid
        t.integer :acs_set_id
        t.boolean :read_only, :default => false
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:course_of_actions, :guid)
      add_index :course_of_actions, :guid
    end

    if !ActiveRecord::Base.connection.index_exists?(:course_of_actions, :stix_id)
      add_index :course_of_actions, :stix_id
    end
    
    if !ActiveRecord::Base.connection.table_exists?(:indicators_course_of_actions)
      create_table :indicators_course_of_actions do |t|
        t.string :stix_indicator_id
        t.string :course_of_action_id
        t.timestamps
        t.string :guid
        t.string :user_guid
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:indicators_course_of_actions, :stix_indicator_id)
      add_index :indicators_course_of_actions, :stix_indicator_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:indicators_course_of_actions, :course_of_action_id)
      add_index :indicators_course_of_actions, :course_of_action_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:indicators_course_of_actions, :guid)
      add_index :indicators_course_of_actions, :guid
    end
    
    if !ActiveRecord::Base.connection.table_exists?(:packages_course_of_actions)
      create_table :packages_course_of_actions do |t|
        t.string :stix_package_id
        t.string :course_of_action_id
        t.timestamps
        t.string :guid
        t.string :user_guid
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:packages_course_of_actions, :stix_package_id)
      add_index :packages_course_of_actions, :stix_package_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:packages_course_of_actions, :course_of_action_id)
      add_index :packages_course_of_actions, :course_of_action_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:packages_course_of_actions, :guid)
      add_index :packages_course_of_actions, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:parameter_observables)
      create_table :parameter_observables do |t|
        t.string :cybox_object_id        # The unique ID of the parameter_observable itself
        t.boolean :is_imported, :default => false
        t.string :remote_object_id       # Unique ID of the CYBOX object
        t.string :remote_object_type     # The type of CYBOX object referenced
        t.string :stix_course_of_action_id      # The unique ID of an course_of_action
        t.string :user_guid
        t.string :guid
        t.boolean :read_only, :default => false
        t.timestamps
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:parameter_observables, :cybox_object_id)
      add_index :parameter_observables, :cybox_object_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:parameter_observables, :remote_object_id)
      add_index :parameter_observables, :remote_object_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:parameter_observables, :stix_course_of_action_id)
      add_index :parameter_observables, :stix_course_of_action_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:parameter_observables, :guid)
      add_index :parameter_observables, :guid
    end

  end
  
    
  def down
    remove_index :course_of_actions, :guid
    remove_index :course_of_actions, :stix_id

    remove_index :indicators_course_of_actions, :stix_indicator_id
    remove_index :indicators_course_of_actions, :course_of_action_id
    remove_index :indicators_course_of_actions, :guid

    remove_index :packages_course_of_actions, :stix_package_id
    remove_index :packages_course_of_actions, :course_of_action_id
    remove_index :packages_course_of_actions, :guid

    remove_index :parameter_observables, :cybox_object_id
    remove_index :parameter_observables, :remote_object_id
    remove_index :parameter_observables, :stix_course_of_action_id
    remove_index :parameter_observables, :guid

    drop_table :course_of_actions
    drop_table :indicators_course_of_actions
    drop_table :packages_course_of_actions
    drop_table :parameter_observables
  end
end
