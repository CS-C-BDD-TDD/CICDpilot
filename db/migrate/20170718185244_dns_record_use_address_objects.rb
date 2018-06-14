class DnsRecordUseAddressObjects < ActiveRecord::Migration
   class MDnsRecord < ActiveRecord::Base
    self.table_name = "cybox_dns_records"
    include Auditable
    belongs_to :address, class_name: 'MAddress', primary_key: :cybox_object_id, foreign_key: :address_cybox_object_id
    belongs_to :domain, class_name: 'MDomain', primary_key: :cybox_object_id, foreign_key: :domain_cybox_object_id

    has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  end

  class MAddress < ActiveRecord::Base
    self.table_name = "cybox_addresses"
    has_many :dns_record_addresses, class_name: 'MDnsRecord', primary_key: :cybox_object_id, foreign_key: :addresss_cybox_object_id
  end

   class MDomain < ActiveRecord::Base
     self.table_name = "cybox_domains"
     has_many :dns_record_domains, class_name: 'MDnsRecord', primary_key: :cybox_object_id, foreign_key: :domain_cybox_object_id
   end

  def up
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

    # first we need to create another column for foreign keys for email address x_orig_ip
    if !ActiveRecord::Base.connection.column_exists?(:cybox_dns_records, :address_cybox_object_id)
      add_column :cybox_dns_records, :address_cybox_object_id, :string
      add_column :cybox_dns_records, :domain_cybox_object_id, :string
      add_column :cybox_dns_records, :record_name, :string
      add_column :cybox_dns_records, :record_type, :string
      add_column :cybox_dns_records, :ttl, :string
      add_column :cybox_dns_records, :flags, :string
      add_column :cybox_dns_records, :data_length, :string
      add_column :cybox_dns_records, :record_name_c, :string
      add_column :cybox_dns_records, :record_type_c, :string
      add_column :cybox_dns_records, :ttl_c, :string
      add_column :cybox_dns_records, :flags_c, :string
      add_column :cybox_dns_records, :data_length_c, :string
    end

    # then we need to find or create all address objects for the email message and link them to the email
    # the columns we are changing are sender, reply_to, from, x_originating_ip
    MDnsRecord.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"

      address_fields = {
        :address_value_normalized => :address_cybox_object_id
      }

      domain_fields = {domain_normalized: :domain_cybox_object_id}

      group.each do |obj|
          address_fields.each do |field|
            if obj[field.first].present? && obj[field.second].blank?
              # first try to find the stix marking associated with the remote object field.
              add_marking = StixMarking.where(:remote_object_id => obj.guid, :remote_object_field => field.first).first
              if add_marking.present?
                add = Address.find_or_create_by({address_value_raw: obj[field.first]}, add_marking)
              else
                add = Address.find_or_create_by(address_value_raw: obj[field.first])
              end

              if add.present?
                if add.category != "ipv4-addr" && add.category != "ipv6-addr"
                  if Address.valid_ipv4_value?(obj[field.first])
                    add.category = "ipv4-addr"
                  elsif Address.valid_ipv6_value?(obj[field.first])
                    add.category = "ipv6-addr"
                  end
                  add.save!
                end
                obj[field.second] = add.cybox_object_id

                # Audit the add
                audit = Audit.basic
                audit.message = "Address '#{add.cybox_object_id}' added to Dns Record '#{obj.cybox_object_id}'"
                audit.audit_type = :dns_record_address_link
                other_audit = audit.dup
                other_audit.item = add
                add.audits << other_audit
                obj_audit = audit.dup
                obj_audit.item = obj
                obj_audit.item_type_audited = "DnsRecord"
                obj.audits << obj_audit
              end
            end
          end

          domain_fields.each do |field|
            if obj[field.first].present? && obj[field.second].blank?
              # first try to find the stix marking associated with the remote object field.
              add_marking = StixMarking.where(:remote_object_id => obj.guid, :remote_object_field => field.first).first
              if add_marking.present?
                domain = Domain.find_or_create_by({name_raw: obj[field.first]}, add_marking)
              else
                domain = Domain.find_or_create_by(name_raw: obj[field.first])
              end

              if domain.present?
                obj[field.second] = domain.cybox_object_id

                # Audit the domain
                audit = Audit.basic
                audit.message = "Domain '#{domain.cybox_object_id}' added to Dns Record '#{obj.cybox_object_id}'"
                audit.audit_type = :dns_record_domain_link
                other_audit = audit.dup
                other_audit.item = domain
                domain.audits << other_audit
                obj_audit = audit.dup
                obj_audit.item = obj
                obj_audit.item_type_audited = "DnsRecord"
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

    if !ActiveRecord::Base.connection.column_exists?(:cybox_dns_records, :address_cybox_object_id)
      remove_column :cybox_dns_records, :address_cybox_object_id, :string
      remove_column :cybox_dns_records, :domain_cybox_object_id, :string
      remove_column :cybox_dns_records, :record_name, :string
      remove_column :cybox_dns_records, :record_type, :string
      remove_column :cybox_dns_records, :ttl, :string
      remove_column :cybox_dns_records, :flags, :string
      remove_column :cybox_dns_records, :data_length, :string
      remove_column :cybox_dns_records, :record_name_c, :string
      remove_column :cybox_dns_records, :record_type_c, :string
      remove_column :cybox_dns_records, :ttl_c, :string
      remove_column :cybox_dns_records, :flags_c, :string
      remove_column :cybox_dns_records, :data_length_c, :string
    end

  end
end
