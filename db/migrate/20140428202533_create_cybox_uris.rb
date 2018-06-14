class CreateCyboxUris < ActiveRecord::Migration
  def change
    create_table :cybox_uris do |t|
      t.datetime :created_at
      t.string :cybox_hash
      t.string :cybox_object_id
      t.string :label
      t.datetime :updated_at
      t.string :uri_normalized
      t.string :uri_raw
      t.string :uri_type, default: 'URL'    # Other valid choices are 'General URN' and 'Domain Name'
    end

      add_index :cybox_uris, :cybox_object_id
      add_index :cybox_uris, :uri_normalized
  end
end
