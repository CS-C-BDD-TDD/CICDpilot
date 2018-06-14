namespace :email_message_addresses do
  task :fix => :environment do
    class MEmailMessage < ActiveRecord::Base
    self.table_name = "cybox_email_messages"
    include Auditable

    belongs_to :sender_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :sender_cybox_object_id
    belongs_to :reply_to_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :reply_to_cybox_object_id
    belongs_to :from_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :from_cybox_object_id
    belongs_to :x_ip_address, class_name: 'Address', primary_key: :cybox_object_id, foreign_key: :x_ip_cybox_object_id

    has_many :stix_markings, primary_key: :guid, as: :remote_object, dependent: :destroy
  end

  class MAddress < ActiveRecord::Base
    self.table_name = "cybox_addresses"

    has_many :email_senders, class_name: 'MEmailMessage', primary_key: :cybox_object_id, foreign_key: :sender_cybox_object_id
    has_many :email_reply_tos, class_name: 'MEmailMessage', primary_key: :cybox_object_id, foreign_key: :reply_to_cybox_object_id
    has_many :email_froms, class_name: 'MEmailMessage', primary_key: :cybox_object_id, foreign_key: :from_cybox_object_id
    has_many :email_x_ips, class_name: 'MEmailMessage', primary_key: :cybox_object_id, foreign_key: :x_ip_cybox_object_id
  end

  ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

  # first we need to create another column for foreign keys for email address x_orig_ip
  if !ActiveRecord::Base.connection.column_exists?(:cybox_email_messages, :x_ip_cybox_object_id)
    add_column :cybox_email_messages, :x_ip_cybox_object_id, :string
  end

  # then we need to find or create all address objects for the email message and link them to the email
  # the columns we are changing are sender, reply_to, from, x_originating_ip
  MEmailMessage.find_in_batches.with_index do |group,batch|
      puts "Processing group ##{batch}"

      group.each do |obj|

      address_fields = {
        :sender_normalized => {sender_address: []}, 
        :reply_to_normalized => {reply_to_address: []}, 
        :from_normalized => {from_address: []}, 
        :x_originating_ip => {x_ip_address: []}
      }

        begin
          address_fields.keys.each do |key|
            if obj[key].present?
              # first try to find the stix marking associated with the remote object field.
              add_marking = StixMarking.where(:remote_object_id => obj.guid, :remote_object_field => key).first
              if add_marking.present?
                add = Address.find_or_create_by({address_value_raw: obj[key]}, add_marking)
              else
                add = Address.find_or_create_by(address_value_raw: obj[key])
              end
              if add.present?
                address_fields[key].first.second << add

                # Audit the add
                audit = Audit.basic
                audit.message = "Address '#{add.cybox_object_id}' added to Email '#{obj.cybox_object_id}'"
                audit.audit_type = :email_address_link
                other_audit = audit.dup
                other_audit.item = add
                add.audits << other_audit
                obj_audit = audit.dup
                obj_audit.item = obj
                obj_audit.item_type_audited = "EmailMessage"
                obj.audits << obj_audit
              end
            end
          end
          obj.from_address = address_fields[:from_normalized].first[1][0] if address_fields[:from_normalized].first[1][0].present?
          obj.sender_address = address_fields[:sender_normalized].first[1][0] if address_fields[:sender_normalized].first[1][0].present?
          obj.reply_to_address = address_fields[:reply_to_normalized].first[1][0] if address_fields[:reply_to_normalized].first[1][0].present?
          obj.x_ip_address = address_fields[:x_originating_ip].first[1][0] if address_fields[:x_originating_ip].first[1][0].present?

          obj.save!
        rescue Exception => e
          puts "Could not transition Email Message id: #{obj.id}, Exception: #{e.to_s}"
        end
      end
    end

  ::Sunspot.session = ::Sunspot.session.original_session

  end
end