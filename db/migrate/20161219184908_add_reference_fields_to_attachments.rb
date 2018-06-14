class AddReferenceFieldsToAttachments < ActiveRecord::Migration
  def change
  	add_column :uploaded_files, :reference_title, :string
  	add_column :uploaded_files, :reference_number, :string
  	add_column :uploaded_files, :reference_link, :string
  end
end
