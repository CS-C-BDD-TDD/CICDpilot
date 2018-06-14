class AddPortionMarkingCacheToUploads < ActiveRecord::Migration
  def change
  	add_column :uploaded_files,:portion_marking,:string
  end
end
