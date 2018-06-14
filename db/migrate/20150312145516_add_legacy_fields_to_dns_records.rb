class AddLegacyFieldsToDnsRecords < ActiveRecord::Migration
  def change
    add_column :cybox_dns_records, :legacy_record_name, :string
    add_column :cybox_dns_records, :legacy_record_type, :string
    add_column :cybox_dns_records, :legacy_ttl, :integer
    add_column :cybox_dns_records, :legacy_flags, :string
    add_column :cybox_dns_records, :legacy_data_length, :integer
    add_column :cybox_dns_records, :legacy_record_data, :text
  end
end
