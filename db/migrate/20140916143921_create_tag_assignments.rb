class CreateTagAssignments < ActiveRecord::Migration
  def change
    create_table :tag_assignments do |t|
      t.datetime :created_at, :null => false
      t.string  :remote_object_guid, :null => false
      t.string   :remote_object_type, :null => false  # Type of STIX object
      t.string :justification
      t.integer  :tag_id
      t.string :tag_guid, :null => false
      t.string   :user_guid                             # FK to USERS table
    end
  end
end
