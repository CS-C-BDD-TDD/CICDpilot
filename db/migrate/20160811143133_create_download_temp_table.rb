class CreateDownloadTempTable < ActiveRecord::Migration
  def up
    create_table :download_temp do |t|
      t.string :user_guid, null: false
      t.binary :download, null: false
    end

    add_index :download_temp, :user_guid
  end

  def down
    drop_table :download_temp

    remove_index :download_temp, column: :user_guid
  end
end
