class AddOverwriteToUploadedFiles < ActiveRecord::Migration
  def change
   add_column :uploaded_files, :overwrite, :boolean, default: false, null: false
  end
end
