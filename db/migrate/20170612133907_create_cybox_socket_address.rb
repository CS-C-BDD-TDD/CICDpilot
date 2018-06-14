class CreateCyboxSocketAddress < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:cybox_socket_addresses)
      create_table :cybox_socket_addresses do |t|
        t.string :cybox_hash
        t.string :cybox_object_id
        t.string :addresses_normalized_cache
        t.string :hostnames_normalized_cache
        t.string :ports_normalized_cache
        t.string :name_condition
        t.string :apply_condition
        t.string :guid
        t.string :portion_marking
        t.boolean :is_reference
        t.boolean :read_only, :default => false
        t.timestamps :null => true
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_socket_addresses, :guid)
      add_index :cybox_socket_addresses, :guid
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_socket_addresses, :cybox_object_id)
      add_index :cybox_socket_addresses, :cybox_object_id
    end

    if !ActiveRecord::Base.connection.table_exists?(:socket_address_addresses)
      create_table :socket_address_addresses do |t|
        t.string :socket_address_id
        t.string :address_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_addresses, :socket_address_id)
      add_index :socket_address_addresses, :socket_address_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_addresses, :address_id)
      add_index :socket_address_addresses, :address_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_addresses, :guid)
      add_index :socket_address_addresses, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:socket_address_hostnames)
      create_table :socket_address_hostnames do |t|
        t.string :socket_address_id
        t.string :hostname_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_hostnames, :socket_address_id)
      add_index :socket_address_hostnames, :socket_address_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_hostnames, :hostname_id)
      add_index :socket_address_hostnames, :hostname_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_hostnames, :guid)
      add_index :socket_address_hostnames, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:socket_address_ports)
      create_table :socket_address_ports do |t|
        t.string :socket_address_id
        t.string :port_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_ports, :socket_address_id)
      add_index :socket_address_ports, :socket_address_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_ports, :port_id)
      add_index :socket_address_ports, :port_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:socket_address_ports, :guid)
      add_index :socket_address_ports, :guid
    end

  end
  
  def down
    if ActiveRecord::Base.connection.index_exists?(:cybox_socket_addresses, :guid)
      remove_index :cybox_socket_addresses, :guid
    end
    
    if ActiveRecord::Base.connection.index_exists?(:cybox_socket_addresses, :cybox_object_id)
      remove_index :cybox_socket_addresses, :cybox_object_id
    end


    if ActiveRecord::Base.connection.index_exists?(:socket_address_addresses, :socket_address_id)
      remove_index :socket_address_addresses, :socket_address_id
    end

    if ActiveRecord::Base.connection.index_exists?(:socket_address_addresses, :address_id)
      remove_index :socket_address_addresses, :address_id
    end

    if ActiveRecord::Base.connection.index_exists?(:socket_address_addresses, :guid)
      remove_index :socket_address_addresses, :guid
    end


    if ActiveRecord::Base.connection.index_exists?(:socket_address_hostnames, :socket_address_id)
      remove_index :socket_address_hostnames, :socket_address_id
    end

    if ActiveRecord::Base.connection.index_exists?(:socket_address_hostnames, :hostname_id)
      remove_index :socket_address_hostnames, :hostname_id
    end

    if ActiveRecord::Base.connection.index_exists?(:socket_address_hostnames, :guid)
      remove_index :socket_address_hostnames, :guid
    end


    if ActiveRecord::Base.connection.index_exists?(:socket_address_ports, :socket_address_id)
      remove_index :socket_address_ports, :socket_address_id
    end

    if ActiveRecord::Base.connection.index_exists?(:socket_address_ports, :port_id)
      remove_index :socket_address_ports, :port_id
    end

    if ActiveRecord::Base.connection.index_exists?(:socket_address_ports, :guid)
      remove_index :socket_address_ports, :guid
    end
    

    if ActiveRecord::Base.connection.table_exists?(:cybox_socket_addresses)
      drop_table :cybox_socket_addresses
    end

    if ActiveRecord::Base.connection.table_exists?(:socket_address_addresses)
      drop_table :socket_address_addresses
    end

    if ActiveRecord::Base.connection.table_exists?(:socket_address_hostnames)
      drop_table :socket_address_hostnames
    end

    if ActiveRecord::Base.connection.table_exists?(:socket_address_ports)
      drop_table :socket_address_ports
    end
  end

end
