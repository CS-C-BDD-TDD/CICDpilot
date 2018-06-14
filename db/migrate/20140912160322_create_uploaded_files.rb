# FYI: Legal values for status are: N - Not Loaded, I - In progress,
# S - Successful, F - Failure, and C - Canceled. That will be enforced by the
# UploadedFile model.

class CreateUploadedFiles < ActiveRecord::Migration
  def change
    create_table :uploaded_files do |t|
      t.boolean  :is_attachment, :null => false, :default => false
      t.string   :file_name, :null => false
      t.integer  :file_size
      t.string   :status, :limit => 1, :default => 'N', :null => false
      t.boolean  :validate_only, :default => false, :null => false
      t.string   :user_guid

      t.timestamps
    end

    add_index :uploaded_files, :user_guid
  end
end
