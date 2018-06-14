class CreateOriginalInput < ActiveRecord::Migration
  def change
    create_table :original_input do |t|
      t.boolean  :is_attachment, null: false, default: false
      t.string   :mime_type, null: false
      t.binary   :raw_content, null: false
      t.string   :remote_object_id
      t.string   :remote_object_type
      t.integer  :uploaded_file_id, null: false
      t.timestamps
    end

    add_index :original_input, :remote_object_id
    add_index :original_input, :uploaded_file_id
  end
end
