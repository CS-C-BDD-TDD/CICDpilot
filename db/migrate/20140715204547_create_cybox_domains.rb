class CreateCyboxDomains < ActiveRecord::Migration

  # legal values for name_type include 'FQDN' (Fully Qualified Domain Name) and
  # 'TLD' (Top-Level Domain, like .com or .org).

  def change
    create_table :cybox_domains do |t|
      t.string :cybox_hash
      t.string :cybox_object_id
      t.string :name_raw
      t.string :name_condition, 'Equals'
      t.string :name_normalized
      t.string :name_type, null: false, default: 'FQDN'
      t.string :root_domain
      t.timestamps
    end

    add_index :cybox_domains, :cybox_object_id
  end
end
