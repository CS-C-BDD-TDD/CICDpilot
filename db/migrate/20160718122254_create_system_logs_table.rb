class CreateSystemLogsTable < ActiveRecord::Migration
  def up
    create_table :system_logs do |t|
      t.string :stix_package_id, null: false
      t.string :sanitized_package_id
      t.timestamp :timestamp, null: false
      t.string :source, null: false
      t.string :log_level, null: false
      t.string :message, null: false
      t.text :text
      t.timestamps
    end

    add_index :id_mappings, :after_id
  end

  def down
    drop_table :system_logs

    remove_index :id_mappings, column: :after_id
  end
end
