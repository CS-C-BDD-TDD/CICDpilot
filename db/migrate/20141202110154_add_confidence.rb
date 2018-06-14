class AddConfidence < ActiveRecord::Migration
  def change
    create_table :stix_confidences do |t|
      t.string :value, null: false
      t.text :description
      t.string :source
      t.boolean :is_official, default: false
      t.integer :confidence_num, null: false
      t.datetime :created_at
      t.datetime :stix_timestamp

      t.string :user_guid
      t.string :remote_object_type, null: false
      t.string :remote_object_id, null: false
      t.string :guid
    end
  end
end
