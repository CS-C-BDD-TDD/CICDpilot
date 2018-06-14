class CreateCyboxFileHashes < ActiveRecord::Migration
  def change
    create_table :cybox_file_hashes do |t|
      t.datetime :created_at
      t.string :cybox_file_id
      t.string :cybox_hash
      t.string :cybox_object_id
      t.string :fuzzy_hash_value
      t.string :fuzzy_hash_value_normalized
      t.string :hash_condition, default: 'Equals'
      t.string :hash_type
      t.string :hash_type_vocab_name
      t.string :hash_type_vocab_ref
      t.string :simple_hash_value
      t.string :simple_hash_value_normalized
      t.datetime :updated_at
    end

      add_index :cybox_file_hashes, :cybox_file_id
      add_index :cybox_file_hashes, :cybox_object_id
      add_index :cybox_file_hashes, :fuzzy_hash_value_normalized
      add_index :cybox_file_hashes, :simple_hash_value_normalized
  end
end
