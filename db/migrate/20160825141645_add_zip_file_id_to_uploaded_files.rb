class AddZipFileIdToUploadedFiles < ActiveRecord::Migration
  def change
    add_column :uploaded_files, :zip_file_id, :integer
  end
end
