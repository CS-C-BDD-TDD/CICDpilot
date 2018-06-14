class CreateStixRelatedObjects < ActiveRecord::Migration
  def change
    create_table :stix_related_objects do |t|
      t.string :remote_dest_object_type
      t.string :remote_dest_object_guid
      t.string :remote_src_object_type
      t.string :remote_src_object_guid
      t.string :stix_information_source_id
      t.string :relationship_type
      t.string :guid
      t.string :created_by_user_guid
      t.string :updated_by_user_guid
      t.timestamps
    end
  end
end
