class CreateCyboxAddresses < ActiveRecord::Migration
  def self.up
    create_table :cybox_addresses do |t|
      t.string :address_value_raw
      t.string :address_value_normalized
      t.string :category
      t.string :cybox_hash
      t.string :cybox_object_id
      t.decimal :ip_value_calculated_start, :precision => 10, :scale => 0
      t.decimal :ip_value_calculated_end, :precision => 10, :scale => 0
      t.timestamps
    end

    add_index :cybox_addresses, :cybox_object_id
  end

  def self.down
    drop_table :cybox_addresses
  end
end
