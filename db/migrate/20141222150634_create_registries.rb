class CreateRegistries < ActiveRecord::Migration
  def change
    create_table :cybox_win_registry_keys do |t|
      t.string :cybox_object_id
      t.string :cybox_hash
      t.string :hive
      t.string :key
      t.string :guid

      t.timestamps
    end

    add_index :cybox_win_registry_keys, :cybox_object_id
    add_index :cybox_win_registry_keys, :guid

    create_table :cybox_win_registry_values do |t|
      t.string :cybox_win_reg_key_id
      t.text :reg_name
      t.text :reg_value
      t.string :guid
    end

    add_index :cybox_win_registry_values, :cybox_win_reg_key_id
  end
end
