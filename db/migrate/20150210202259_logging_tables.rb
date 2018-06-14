class LoggingTables < ActiveRecord::Migration
  def change
    create_table :authentication_logs do |t|
      t.text :info
      t.string :event
      t.string :access_mode
      t.string :user_guid

      t.timestamps
    end

    create_table :search_logs do |t|
      t.text :query
      t.string :user_guid

      t.timestamps
    end
  end
end
