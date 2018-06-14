class AddIsCiscpToCyboxFileHashes < ActiveRecord::Migration
  def change
  	add_column :cybox_file_hashes, :is_ciscp, :boolean, :default => false
  	add_column :questions, :is_ciscp, :boolean, :default => false
  	add_column :resource_records, :is_ciscp, :boolean, :default => false
  end
end
