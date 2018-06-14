class MoveLabelFromUriTableToLinkTable < ActiveRecord::Migration
  def change
    create_table :cybox_links do |t|
      t.datetime :created_at
      t.string :cybox_hash
      t.string :cybox_object_id
      t.string :label
      t.string :uri_object_id
      t.datetime :updated_at
      t.string :guid
    end

    add_index :cybox_links, :cybox_object_id
    add_index :cybox_links, :uri_object_id
    add_index :cybox_links, :guid

    Rake::Task['uri_to_link'].execute

    rename_column :cybox_uris, :label, :old_label
  end
end
