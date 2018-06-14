class CreateCyboxFiles < ActiveRecord::Migration
  def change
    create_table :cybox_files do |t|
      t.datetime :created_at
      t.string :cybox_hash
      t.string :cybox_object_id
      t.string :file_extension
      t.string :file_name
      t.string :file_name_condition, default: 'Equals'
      t.string :file_path
      t.string :file_path_condition, default: 'Equals'
      t.integer :size_in_bytes
      t.string :size_in_bytes_condition, default: 'Equals'
      t.datetime :updated_at
    end

    add_index :cybox_files, :cybox_object_id
  end
end
