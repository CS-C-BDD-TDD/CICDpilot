class CreateAvpMessages < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:avp_messages)
      create_table :avp_messages do |t|
        t.text :prohibited
        t.text :avp_errors
        t.string :guid
        t.boolean :avp_valid
        t.datetime :timestamp
        t.timestamps :null => true
      end

      add_index :avp_messages, :guid
    end

    if ActiveRecord::Base.connection.column_exists?(:uploaded_files, :avp_validation)
      remove_column :uploaded_files, :avp_validation
      remove_column :uploaded_files, :avp_fail_continue
      remove_column :uploaded_files, :avp_valid
      remove_column :uploaded_files, :avp_message_id
      add_column :uploaded_files, :avp_validation, :boolean
      add_column :uploaded_files, :avp_fail_continue, :boolean
      add_column :uploaded_files, :avp_valid, :boolean
      add_column :uploaded_files, :avp_message_id, :string
    else
      add_column :uploaded_files, :avp_validation, :boolean
      add_column :uploaded_files, :avp_fail_continue, :boolean
      add_column :uploaded_files, :avp_valid, :boolean
      add_column :uploaded_files, :avp_message_id, :string
    end
  end

  def down
    if ActiveRecord::Base.connection.table_exists?(:avp_messages)
      remove_index :avp_messages, :guid
      drop_table :avp_messages
    end

    if ActiveRecord::Base.connection.column_exists?(:uploaded_files, :avp_validation)
      remove_column :uploaded_files, :avp_validation
      remove_column :uploaded_files, :avp_fail_continue
      remove_column :uploaded_files, :avp_valid
      remove_column :uploaded_files, :avp_message_id
    end
  end
end
