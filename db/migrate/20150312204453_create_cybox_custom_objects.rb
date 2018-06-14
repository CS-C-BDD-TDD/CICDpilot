class CreateCyboxCustomObjects < ActiveRecord::Migration
  def change
    create_table :cybox_custom_objects do |t|
      t.string :custom_name
      t.string :string
      t.string :string_description
      t.string :cybox_object_id
      t.string :cybox_hash
      t.string :user_guid
      t.string :guid
      t.timestamps
    end

    add_index :cybox_custom_objects, :cybox_object_id
  end
end
