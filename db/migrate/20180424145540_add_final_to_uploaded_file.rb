class AddFinalToUploadedFile < ActiveRecord::Migration
  def up
    unless ActiveRecord::Base.connection.column_exists?(:uploaded_files, :final)
      add_column :uploaded_files, :final, :boolean, :default => false
    end
  end

  def down
    if ActiveRecord::Base.connection.column_exists?(:uploaded_files, :final)
      remove_column :uploaded_files, :final
    end
  end
end
