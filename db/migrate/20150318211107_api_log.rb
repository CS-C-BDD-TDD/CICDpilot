class ApiLog < ActiveRecord::Migration
  def change
    create_table :api_logs do |t|
      t.string :action
      t.string :controller
      t.text :uri
      t.string :user_guid
      t.integer :count
      t.string :query_source_entity

      t.timestamps
    end
  end
end
