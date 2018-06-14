class CreateGfis < ActiveRecord::Migration
  def change
    create_table :gfis do |t|
      t.text :gfi_source_name
      t.text :gfi_action_name
      t.text :gfi_action_name_class
      t.text :gfi_action_name_subclass
      t.text :gfi_ps_regex
      t.text :gfi_ps_regex_class
      t.text :gfi_ps_regex_subclass
      t.text :gfi_cs_regex
      t.text :gfi_cs_regex_class
      t.text :gfi_cs_regex_subclass
      t.text :gfi_exp_sig_loc
      t.text :gfi_exp_sig_loc_class
      t.text :gfi_exp_sig_loc_subclass
      t.integer :gfi_bluesmoke_id
      t.integer :gfi_uscert_sid
      t.text :gfi_notes
      t.text :gfi_notes_class
      t.text :gfi_notes_subclass
      t.text :gfi_status
      t.text :gfi_uscert_doc
      t.text :gfi_uscert_doc_class
      t.text :gfi_uscert_doc_subclass
      t.text :gfi_special_inst
      t.text :gfi_special_inst_class
      t.text :gfi_special_inst_subclass
      t.text :gfi_type
      t.text :guid
    end

    add_column :cybox_addresses, :gfi_id, :integer
    add_column :cybox_domains, :gfi_id, :integer
    add_column :cybox_email_messages, :gfi_id, :integer
    add_column :cybox_files, :gfi_id, :integer
    add_column :cybox_dns_records, :gfi_id, :integer

    add_index :cybox_addresses, :gfi_id
    add_index :cybox_domains, :gfi_id
    add_index :cybox_email_messages, :gfi_id
    add_index :cybox_files, :gfi_id
    add_index :cybox_dns_records, :gfi_id

  end
end