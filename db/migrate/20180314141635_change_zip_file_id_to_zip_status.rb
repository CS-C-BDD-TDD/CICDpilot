class ChangeZipFileIdToZipStatus < ActiveRecord::Migration
  def change
    remove_column :uploaded_files, :zip_file_id
    add_column :uploaded_files, :zip_status, :string
  end
end
