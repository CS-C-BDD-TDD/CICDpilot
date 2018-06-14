class CreateCyboxPorts < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:cybox_ports)
      create_table :cybox_ports do |t|
        t.string :cybox_hash
        t.string :cybox_object_id
        t.string :port
        t.string :port_c
        t.string :layer4_protocol
        t.string :layer4_protocol_c
        t.timestamps
        t.string :guid
        t.string :portion_marking
        t.boolean :read_only, :default => false
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_ports, :guid)
      add_index :cybox_ports, :guid
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:cybox_ports, :cybox_object_id)
      add_index :cybox_ports, :cybox_object_id
    end
  end
  
  def down
    remove_index :cybox_ports, :guid
    remove_index :cybox_ports, :cybox_object_id
    
    drop_table :cybox_ports
  end
end
