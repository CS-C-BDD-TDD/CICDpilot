class AddPermissionRelatedTables < ActiveRecord::Migration
  def up
    create_table :groups do |t|
      t.string :name
      t.string :description
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end

    create_table :permissions do |t|
      t.string :name
      t.string :display_name
      t.string :description
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end

    create_table :groups_permissions do |t|
      t.integer :group_id
      t.integer :permission_id
      t.integer :created_by_id
      t.timestamps
    end
    remove_column :groups_permissions, :updated_at

    create_table :users_groups do |t|
      t.integer :group_id
      t.string :user_guid
      t.integer :created_by_id

      t.timestamps
    end
    remove_column :users_groups, :updated_at
  end

  def down
    drop_table :groups
    drop_table :permissions
    drop_table :groups_permissions
    drop_table :users_groups
  end
end
