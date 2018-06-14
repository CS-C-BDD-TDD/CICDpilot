class ExpansionOfNetworkConnection < ActiveRecord::Migration
  class MNetworkConnection < ActiveRecord::Base
    self.table_name = "cybox_network_connections"
    include Auditable
    belongs_to :address, class_name: 'MSocketAddress', primary_key: :cybox_object_id, foreign_key: :address_cybox_object_id

    has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  end

  class MSocketAddress < ActiveRecord::Base
    self.table_name = "cybox_socket_addresses"
    has_many :dns_record_addresses, class_name: 'MNetworkConnection', primary_key: :cybox_object_id, foreign_key: :addresss_cybox_object_id
  end

  def up
    if !ActiveRecord::Base.connection.table_exists?(:layer_seven_connections)
      create_table :layer_seven_connections do |t|
        t.string :guid
        t.string :cybox_hash
        t.string :portion_marking
        t.string :http_session_id
        t.string :dns_query_cache
        t.boolean :is_reference
        t.boolean :read_only, :default => false
        t.timestamps :null => true
      end
    end
    
    if !ActiveRecord::Base.connection.index_exists?(:layer_seven_connections, :guid)
      add_index :layer_seven_connections, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:lsc_dns_queries)
      create_table :lsc_dns_queries do |t|
        t.string :layer_seven_connection_id
        t.string :dns_query_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:lsc_dns_queries, :layer_seven_connection_id)
      add_index :lsc_dns_queries, :layer_seven_connection_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:lsc_dns_queries, :dns_query_id)
      add_index :lsc_dns_queries, :dns_query_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:lsc_dns_queries, :guid)
      add_index :lsc_dns_queries, :guid
    end

    if !ActiveRecord::Base.connection.table_exists?(:nc_layer_seven_connections)
      create_table :nc_layer_seven_connections do |t|
        t.string :network_connection_id
        t.string :layer_seven_connection_id
        t.string :guid
        t.string :user_guid
        t.timestamps :null => true
      end
    end

    if !ActiveRecord::Base.connection.index_exists?(:nc_layer_seven_connections, :network_connection_id)
      add_index :nc_layer_seven_connections, :network_connection_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:nc_layer_seven_connections, :layer_seven_connection_id)
      add_index :nc_layer_seven_connections, :layer_seven_connection_id
    end

    if !ActiveRecord::Base.connection.index_exists?(:nc_layer_seven_connections, :guid)
      add_index :nc_layer_seven_connections, :guid
    end

    if !ActiveRecord::Base.connection.column_exists?(:cybox_network_connections, :source_socket_address_id)
      add_column :cybox_network_connections, :source_socket_address_id, :string
      add_column :cybox_network_connections, :dest_socket_address_id, :string
    end

    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    
    socket_address_fields = [
      {
        :address => [:source_socket_address, :source_socket_hostname],
        :port => [:source_socket_port],
        :id => [:source_socket_address_id]
      },
      {
        :address => [:dest_socket_address, :dest_socket_hostname],
        :port => [:dest_socket_port],
        :id => [:dest_socket_address_id]
      }
    ]

    MNetworkConnection.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"

      group.each do |obj|
        socket_address_fields.each do |field|
          if obj[field[:id].first].blank? && (obj[field[:address].first].present? || obj[field[:address].second].present? || obj[field[:port].first].present?)
            # first try to find the stix marking associated with the remote object field.
            add_marking = StixMarking.where(:remote_object_id => obj.guid, :remote_object_field => field[:address].first.to_s).first || StixMarking.where(:remote_object_id => obj.guid, :remote_object_field => field[:address].second.to_s).first
            port_marking = StixMarking.where(:remote_object_id => obj.guid, :remote_object_field => field[:port].first.to_s).first

            if add_marking.present? && port_marking.present?
              sub_obj_marking = add_marking.updated_at > port_marking.updated_at ? add_marking : port_marking
            elsif add_marking.present? && port_marking.blank?
              sub_obj_marking = add_marking
            elsif port_marking.present? && add_marking.blank?
              sub_obj_marking = port_marking
            end

            address = obj[field[:address].first] || ''
            hostname = obj[field[:address].second] || ''
            port = obj[field[:port].first] || ''

            if sub_obj_marking.present?
              if address.present?
                sub_obj = SocketAddress.find_or_create_by({address_value_raw: address, port: port}, sub_obj_marking)
              elsif hostname.present?
                sub_obj = SocketAddress.find_or_create_by({hostname_raw: hostname, port: port}, sub_obj_marking)
              else
                sub_obj = SocketAddress.find_or_create_by({port: port}, sub_obj_marking)
              end
            else
              if address.present?
                sub_obj = SocketAddress.find_or_create_by(address_value_raw: address, port: port)
              elsif hostname.present?
                sub_obj = SocketAddress.find_or_create_by(hostname_raw: hostname, port: port)
              else
                sub_obj = SocketAddress.find_or_create_by(port: port)
              end
            end

            # if the field level markings for this field still exist get rid of them if they werent change to object level markings.
            if add_marking.present? || port_marking.present?
              # we need to make sure we didnt change it over to the object level marking of the socket address
              if add_marking.present? && add_marking.remote_object_field.present? && (add_marking.remote_object_field == field[:address].first.to_s || add_marking.remote_object_field == field[:address].second.to_s)
                add_marking.destroy!
              end

              if port_marking.present? && port_marking.remote_object_field.present? && port_marking.remote_object_field == field[:port].first.to_s
                port_marking.destroy!
              end
            end

            if sub_obj.present?
              obj[field[:id].first] = sub_obj.cybox_object_id

              # Audit the sub_obj
              audit = Audit.basic
              audit.message = "Socket Address '#{sub_obj.cybox_object_id}' added to Network Connection '#{obj.cybox_object_id}'"
              audit.audit_type = :socket_address_network_connection_link
              other_audit = audit.dup
              other_audit.item = sub_obj
              sub_obj.audits << other_audit
              obj_audit = audit.dup
              obj_audit.item = obj
              obj_audit.item_type_audited = "NetworkConnection"
              obj.audits << obj_audit
            end
          end
        end

        obj.save!
      end
    end

    ::Sunspot.session = ::Sunspot.session.original_session
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:cybox_network_connections, :source_socket_address_id)
      remove_column :cybox_network_connections, :source_socket_address_id, :string
      remove_column :cybox_network_connections, :dest_socket_address_id, :string
    end

    if ActiveRecord::Base.connection.table_exists?(:layer_seven_connections)
      drop_table :layer_seven_connections
    end

    if ActiveRecord::Base.connection.table_exists?(:lsc_dns_queries)
      drop_table :lsc_dns_queries
    end

    if ActiveRecord::Base.connection.table_exists?(:nc_layer_seven_connections)
      drop_table :nc_layer_seven_connections
    end
    
    if ActiveRecord::Base.connection.index_exists?(:layer_seven_connections, :guid)
      remove_index :layer_seven_connections, :guid
    end

    if ActiveRecord::Base.connection.index_exists?(:lsc_dns_queries, :layer_seven_connection_id)
      remove_index :lsc_dns_queries, :layer_seven_connection_id
    end

    if ActiveRecord::Base.connection.index_exists?(:lsc_dns_queries, :dns_query_id)
      remove_index :lsc_dns_queries, :dns_query_id
    end

    if ActiveRecord::Base.connection.index_exists?(:lsc_dns_queries, :guid)
      remove_index :lsc_dns_queries, :guid
    end

    if ActiveRecord::Base.connection.index_exists?(:nc_layer_seven_connections, :network_connection_id)
      remove_index :nc_layer_seven_connections, :network_connection_id
    end

    if ActiveRecord::Base.connection.index_exists?(:nc_layer_seven_connections, :layer_seven_connection_id)
      remove_index :nc_layer_seven_connections, :layer_seven_connection_id
    end

    if ActiveRecord::Base.connection.index_exists?(:nc_layer_seven_connections, :guid)
      remove_index :nc_layer_seven_connections, :guid
    end
    
  end
end
