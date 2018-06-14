class CreateHumanReviewFields < ActiveRecord::Migration
  def change
    create_table :human_review_fields do |t|
      t.boolean  :is_changed, :default => false, :null => true
      t.integer  :human_review_id
      t.string   :object_field, :null => false     # Name of Field
      t.text     :object_field_revised             # Revised value of field
      t.text     :object_field_original            # Original value of field
      t.string   :object_uid                       # STIX/CYBOX ID of object
      t.string   :object_type                      # Object type
      t.string   :object_sha2                      # SHA2 of the object

      t.timestamps null: false
    end

    add_index :human_review_fields, :human_review_id
  end
end
