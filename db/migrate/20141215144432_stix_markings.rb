# The controlled_structure contains an XPATH construct that identifies the 
# resource being marked; this is an XML matching language that doesn't work
# too well in a relational database. So, the remote_object ID and remote
# object type columns should be used to identify the affected resource if at
# all possible.

class StixMarkings < ActiveRecord::Migration
  def change
    create_table :stix_markings do |t|
      t.string :controlled_structure
      t.boolean :is_reference, null: false, default: false
      t.string :guid
      t.string :marking_model_name
      t.string :marking_model_type
      t.string :marking_name
      t.text :marking_value
      t.string :remote_object_id
      t.string :remote_object_type
      t.string :stix_id
      t.timestamps
    end

    add_index :stix_markings, :remote_object_id
    add_index :stix_markings, :stix_id
  end
end
