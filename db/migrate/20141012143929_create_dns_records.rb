# Just an FYI. A DNS Record with an entry_type of 'A' and an address_class
# of 'IN' is equivalent to a DNS Resolution from Release 5.

class CreateDnsRecords < ActiveRecord::Migration
  def self.up
    create_table :cybox_dns_records do |t|
      t.string :address_class, :default => 'IN'
      t.string :address_value_normalized
      t.string :address_value_raw
      t.string :cybox_hash
      t.string :cybox_object_id
      t.string :description
      t.string :domain_normalized
      t.string :domain_raw
      t.string :entry_type, :default => 'A'
      t.datetime :queried_date
      t.string :guid
      t.timestamps
    end

    add_index :cybox_dns_records, :cybox_object_id
    add_index :cybox_dns_records, :address_value_normalized
    add_index :cybox_dns_records, :domain_normalized
    add_index :cybox_dns_records, :guid
  end

  def self.down
    drop_table :cybox_dns_records
  end
end
