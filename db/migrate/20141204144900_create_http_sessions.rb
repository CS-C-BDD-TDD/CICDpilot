class CreateHttpSessions < ActiveRecord::Migration
  def change
    create_table :cybox_http_sessions do |t|
      t.string :cybox_object_id
      t.string :cybox_hash
      t.string :user_agent
      t.string :guid
      
      t.timestamps
    end

    add_index :cybox_http_sessions, :cybox_object_id
    add_index :cybox_http_sessions, :guid
  end
end
