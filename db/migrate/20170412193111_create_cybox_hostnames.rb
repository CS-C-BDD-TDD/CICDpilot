class CreateCyboxHostnames < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:cybox_hostnames)
      create_table :cybox_hostnames do |t|
        t.string :cybox_hash
        t.string :cybox_object_id
        t.string :hostname_raw
        t.string :hostname_condition, default: 'Equals'
        t.string :hostname_normalized
        t.string :hostname_normalized_c
        t.string :naming_system
        t.string :naming_system_c
        t.boolean :is_domain_name, :default => false
        t.timestamps
        t.string :guid
        t.string :portion_marking
        t.boolean :read_only, :default => false
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_hostnames, :guid)
      add_index :cybox_hostnames, :guid
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_hostnames, :cybox_object_id)
      add_index :cybox_hostnames, :cybox_object_id
    end
  end
  
  
  def down
    remove_index :cybox_hostnames, :guid
    remove_index :cybox_hostnames, :cybox_object_id
    
    drop_table :cybox_hostnames
  end
end
