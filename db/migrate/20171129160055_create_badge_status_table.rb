class CreateBadgeStatusTable < ActiveRecord::Migration
  def up
    if !ActiveRecord::Base.connection.table_exists?(:badge_statuses)
      create_table :badge_statuses do |t|
        t.string :badge_name
        t.string :badge_status
        t.string :remote_object_id
        t.string :remote_object_type
        t.string :guid
        t.string :created_by_user_guid
        t.string :created_by_organization_guid
        t.string :updated_by_user_guid
        t.string :updated_by_organization_guid
        t.boolean :system, :default => false
        t.timestamps :null => true
      end

      add_index :badge_statuses, :guid
    end
  end

  def down
    if ActiveRecord::Base.connection.table_exists?(:badge_statuses)
      drop_table :badge_statuses
    end
  end

end
