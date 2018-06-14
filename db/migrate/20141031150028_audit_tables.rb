class AuditTables < ActiveRecord::Migration
  def change
    create_table :audit_logs do |t|
      t.string :message
      t.text :details
      t.string :audit_type
      t.string :justification
      t.datetime :event_time
      t.string :user_guid
      t.string :system_guid
      t.string :item_type_audited
      t.string :item_guid_audited
      t.string :guid
    end
  end
end
