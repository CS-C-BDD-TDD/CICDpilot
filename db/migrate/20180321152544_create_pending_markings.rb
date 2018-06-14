class CreatePendingMarkings < ActiveRecord::Migration
  def change
    create_table :pending_markings do |t|
      t.string :remote_object_type
      t.string :remote_object_guid

      t.timestamps null: false
    end
    add_index :pending_markings, :remote_object_guid
  end
end
