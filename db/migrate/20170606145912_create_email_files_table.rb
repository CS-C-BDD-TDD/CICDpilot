class CreateEmailFilesTable < ActiveRecord::Migration
  def up
    create_table :email_files do |t|
      t.string :email_message_id
      t.string :cybox_file_id
    end
  end

  def down
    drop_table :email_files
  end
end

